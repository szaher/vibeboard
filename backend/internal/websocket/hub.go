package websocket

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true // Allow connections from any origin
	},
}

type MessageType string

const (
	MessageTypeJoinRoom     MessageType = "join_room"
	MessageTypeLeaveRoom    MessageType = "leave_room"
	MessageTypeGameMove     MessageType = "game_move"
	MessageTypeGameUpdate   MessageType = "game_update"
	MessageTypeChatMessage  MessageType = "chat_message"
	MessageTypePlayerJoined MessageType = "player_joined"
	MessageTypePlayerLeft   MessageType = "player_left"
	MessageTypeError        MessageType = "error"
	MessageTypeHeartbeat    MessageType = "heartbeat"
)

type Message struct {
	Type      MessageType     `json:"type"`
	RoomID    string          `json:"room_id,omitempty"`
	PlayerID  uuid.UUID       `json:"player_id"`
	Data      json.RawMessage `json:"data,omitempty"`
	Timestamp time.Time       `json:"timestamp"`
}

type Client struct {
	ID       uuid.UUID
	UserID   uuid.UUID
	Hub      *Hub
	Conn     *websocket.Conn
	Send     chan []byte
	Rooms    map[string]bool
	LastSeen time.Time
	mutex    sync.RWMutex
}

type Room struct {
	ID      string
	Clients map[uuid.UUID]*Client
	mutex   sync.RWMutex
}

type Hub struct {
	clients    map[uuid.UUID]*Client
	rooms      map[string]*Room
	register   chan *Client
	unregister chan *Client
	broadcast  chan []byte
	mutex      sync.RWMutex
}

func NewHub() *Hub {
	return &Hub{
		clients:    make(map[uuid.UUID]*Client),
		rooms:      make(map[string]*Room),
		register:   make(chan *Client),
		unregister: make(chan *Client),
		broadcast:  make(chan []byte, 256),
	}
}

func (h *Hub) Run() {
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case client := <-h.register:
			h.registerClient(client)

		case client := <-h.unregister:
			h.unregisterClient(client)

		case message := <-h.broadcast:
			h.broadcastMessage(message)

		case <-ticker.C:
			h.cleanupInactiveClients()
		}
	}
}

func (h *Hub) registerClient(client *Client) {
	h.mutex.Lock()
	defer h.mutex.Unlock()

	h.clients[client.ID] = client
	log.Printf("Client %s connected (User: %s)", client.ID, client.UserID)
}

func (h *Hub) unregisterClient(client *Client) {
	h.mutex.Lock()
	defer h.mutex.Unlock()

	if _, ok := h.clients[client.ID]; ok {
		// Remove client from all rooms
		for roomID := range client.Rooms {
			h.removeClientFromRoom(client, roomID)
		}

		delete(h.clients, client.ID)
		close(client.Send)
		log.Printf("Client %s disconnected (User: %s)", client.ID, client.UserID)
	}
}

func (h *Hub) broadcastMessage(message []byte) {
	h.mutex.RLock()
	defer h.mutex.RUnlock()

	for _, client := range h.clients {
		select {
		case client.Send <- message:
		default:
			close(client.Send)
			delete(h.clients, client.ID)
		}
	}
}

func (h *Hub) JoinRoom(clientID uuid.UUID, roomID string) error {
	h.mutex.Lock()
	defer h.mutex.Unlock()

	client, exists := h.clients[clientID]
	if !exists {
		return fmt.Errorf("client not found")
	}

	room, exists := h.rooms[roomID]
	if !exists {
		room = &Room{
			ID:      roomID,
			Clients: make(map[uuid.UUID]*Client),
		}
		h.rooms[roomID] = room
	}

	room.mutex.Lock()
	room.Clients[clientID] = client
	room.mutex.Unlock()

	client.mutex.Lock()
	client.Rooms[roomID] = true
	client.mutex.Unlock()

	// Notify other clients in the room
	h.broadcastToRoom(roomID, Message{
		Type:      MessageTypePlayerJoined,
		RoomID:    roomID,
		PlayerID:  client.UserID,
		Timestamp: time.Now(),
	})

	return nil
}

func (h *Hub) LeaveRoom(clientID uuid.UUID, roomID string) error {
	h.mutex.Lock()
	defer h.mutex.Unlock()

	client, exists := h.clients[clientID]
	if !exists {
		return fmt.Errorf("client not found")
	}

	h.removeClientFromRoom(client, roomID)
	return nil
}

func (h *Hub) removeClientFromRoom(client *Client, roomID string) {
	room, exists := h.rooms[roomID]
	if !exists {
		return
	}

	room.mutex.Lock()
	delete(room.Clients, client.ID)
	isEmpty := len(room.Clients) == 0
	room.mutex.Unlock()

	client.mutex.Lock()
	delete(client.Rooms, roomID)
	client.mutex.Unlock()

	// Notify other clients in the room
	h.broadcastToRoom(roomID, Message{
		Type:      MessageTypePlayerLeft,
		RoomID:    roomID,
		PlayerID:  client.UserID,
		Timestamp: time.Now(),
	})

	// Remove room if empty
	if isEmpty {
		delete(h.rooms, roomID)
	}
}

func (h *Hub) BroadcastToRoom(roomID string, message Message) {
	h.mutex.RLock()
	defer h.mutex.RUnlock()
	h.broadcastToRoom(roomID, message)
}

func (h *Hub) broadcastToRoom(roomID string, message Message) {
	room, exists := h.rooms[roomID]
	if !exists {
		return
	}

	messageBytes, err := json.Marshal(message)
	if err != nil {
		log.Printf("Error marshaling message: %v", err)
		return
	}

	room.mutex.RLock()
	defer room.mutex.RUnlock()

	for _, client := range room.Clients {
		select {
		case client.Send <- messageBytes:
		default:
			close(client.Send)
			delete(room.Clients, client.ID)
		}
	}
}

func (h *Hub) SendToClient(clientID uuid.UUID, message Message) error {
	h.mutex.RLock()
	client, exists := h.clients[clientID]
	h.mutex.RUnlock()

	if !exists {
		return fmt.Errorf("client not found")
	}

	messageBytes, err := json.Marshal(message)
	if err != nil {
		return err
	}

	select {
	case client.Send <- messageBytes:
		return nil
	default:
		return fmt.Errorf("client send channel is full")
	}
}

func (h *Hub) GetRoomClients(roomID string) []uuid.UUID {
	h.mutex.RLock()
	defer h.mutex.RUnlock()

	room, exists := h.rooms[roomID]
	if !exists {
		return []uuid.UUID{}
	}

	room.mutex.RLock()
	defer room.mutex.RUnlock()

	clients := make([]uuid.UUID, 0, len(room.Clients))
	for _, client := range room.Clients {
		clients = append(clients, client.UserID)
	}

	return clients
}

func (h *Hub) cleanupInactiveClients() {
	h.mutex.Lock()
	defer h.mutex.Unlock()

	timeout := 5 * time.Minute
	now := time.Now()

	for clientID, client := range h.clients {
		client.mutex.RLock()
		lastSeen := client.LastSeen
		client.mutex.RUnlock()

		if now.Sub(lastSeen) > timeout {
			log.Printf("Cleaning up inactive client: %s", clientID)
			h.unregister <- client
		}
	}
}

func (h *Hub) HandleWebSocket(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Printf("WebSocket upgrade failed: %v", err)
		return
	}

	clientID := uuid.New()
	client := &Client{
		ID:       clientID,
		UserID:   userID.(uuid.UUID),
		Hub:      h,
		Conn:     conn,
		Send:     make(chan []byte, 256),
		Rooms:    make(map[string]bool),
		LastSeen: time.Now(),
	}

	client.Hub.register <- client

	go client.writePump()
	go client.readPump()
}

func (c *Client) readPump() {
	defer func() {
		c.Hub.unregister <- c
		if err := c.Conn.Close(); err != nil {
			log.Printf("Error closing connection: %v", err)
		}
	}()

	c.Conn.SetReadLimit(512)
	if err := c.Conn.SetReadDeadline(time.Now().Add(60 * time.Second)); err != nil {
		log.Printf("Error setting read deadline: %v", err)
	}
	c.Conn.SetPongHandler(func(string) error {
		if err := c.Conn.SetReadDeadline(time.Now().Add(60 * time.Second)); err != nil {
			log.Printf("Error setting read deadline: %v", err)
		}
		c.mutex.Lock()
		c.LastSeen = time.Now()
		c.mutex.Unlock()
		return nil
	})

	for {
		_, messageBytes, err := c.Conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("WebSocket error: %v", err)
			}
			break
		}

		c.mutex.Lock()
		c.LastSeen = time.Now()
		c.mutex.Unlock()

		var message Message
		if err := json.Unmarshal(messageBytes, &message); err != nil {
			log.Printf("Error unmarshaling message: %v", err)
			continue
		}

		message.PlayerID = c.UserID
		message.Timestamp = time.Now()

		c.handleMessage(message)
	}
}

func (c *Client) writePump() {
	ticker := time.NewTicker(54 * time.Second)
	defer func() {
		ticker.Stop()
		if err := c.Conn.Close(); err != nil {
			log.Printf("Error closing connection: %v", err)
		}
	}()

	for {
		select {
		case message, ok := <-c.Send:
			if err := c.Conn.SetWriteDeadline(time.Now().Add(10 * time.Second)); err != nil {
				return
			}
			if !ok {
				if err := c.Conn.WriteMessage(websocket.CloseMessage, []byte{}); err != nil {
					log.Printf("Error writing close message: %v", err)
				}
				return
			}

			w, err := c.Conn.NextWriter(websocket.TextMessage)
			if err != nil {
				return
			}
			if _, err := w.Write(message); err != nil {
				return
			}

			n := len(c.Send)
			for i := 0; i < n; i++ {
				if _, err := w.Write([]byte{'\n'}); err != nil {
					return
				}
				if _, err := w.Write(<-c.Send); err != nil {
					return
				}
			}

			if err := w.Close(); err != nil {
				return
			}

		case <-ticker.C:
			if err := c.Conn.SetWriteDeadline(time.Now().Add(10 * time.Second)); err != nil {
				return
			}
			if err := c.Conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

func (c *Client) handleMessage(message Message) {
	switch message.Type {
	case MessageTypeJoinRoom:
		if message.RoomID != "" {
			if err := c.Hub.JoinRoom(c.ID, message.RoomID); err != nil {
				log.Printf("Error joining room: %v", err)
			}
		}

	case MessageTypeLeaveRoom:
		if message.RoomID != "" {
			if err := c.Hub.LeaveRoom(c.ID, message.RoomID); err != nil {
				log.Printf("Error leaving room: %v", err)
			}
		}

	case MessageTypeGameMove:
		// Forward game move to room
		if message.RoomID != "" {
			c.Hub.BroadcastToRoom(message.RoomID, message)
		}

	case MessageTypeChatMessage:
		// Forward chat message to room
		if message.RoomID != "" {
			c.Hub.BroadcastToRoom(message.RoomID, message)
		}

	case MessageTypeHeartbeat:
		// Respond with heartbeat
		response := Message{
			Type:      MessageTypeHeartbeat,
			PlayerID:  c.UserID,
			Timestamp: time.Now(),
		}
		responseBytes, _ := json.Marshal(response)
		c.Send <- responseBytes

	default:
		log.Printf("Unknown message type: %s", message.Type)
	}
}
