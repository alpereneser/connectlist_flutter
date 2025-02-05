<template>
  <div class="min-h-screen bg-gray-50">
    <Header />
    <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div class="flex h-[calc(100vh-12rem)] bg-white rounded-lg shadow">
        <!-- Conversations List -->
        <div class="w-1/3 border-r border-gray-200">
          <div class="p-4 border-b border-gray-200">
            <div class="relative">
              <input
                v-model="searchQuery"
                type="text"
                placeholder="Search users..."
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                @input="handleSearch"
              />
              <div v-if="showSearchResults && searchResults.length > 0" class="absolute z-10 w-full mt-1 bg-white border border-gray-200 rounded-lg shadow-lg">
                <div v-for="user in searchResults" :key="user.id" class="p-2 hover:bg-gray-50 cursor-pointer" @click="startChat(user)">
                  <div class="flex items-center">
                    <img :src="user.avatar_url || '/default-avatar.png'" class="w-10 h-10 rounded-full" />
                    <div class="ml-3">
                      <div class="font-medium">{{ user.full_name }}</div>
                      <div class="text-sm text-gray-500">@{{ user.username }}</div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div class="h-full overflow-y-auto">
            <div v-for="chat in conversations" :key="chat.id" 
                 @click="selectChat(chat)"
                 class="p-4 hover:bg-gray-50 cursor-pointer"
                 :class="{'bg-blue-50': selectedChat?.id === chat.id}">
              <div class="flex items-center justify-between">
                <div class="flex items-center">
                  <img 
                    :src="chat.sender_id === currentUser?.id ? chat.receiver_avatar_url : chat.sender_avatar_url" 
                    class="w-12 h-12 rounded-full"
                  />
                  <div class="ml-3">
                    <div class="font-medium">
                      {{ chat.sender_id === currentUser?.id ? chat.receiver_full_name : chat.sender_full_name }}
                    </div>
                    <div class="text-sm text-gray-500">
                      {{ chat.content }}
                    </div>
                  </div>
                </div>
                <div class="text-xs text-gray-500">
                  {{ formatDate(chat.created_at) }}
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Chat Area -->
        <div class="flex-1 flex flex-col">
          <div v-if="selectedChat" class="p-4 border-b border-gray-200 flex items-center justify-between">
            <div class="flex items-center">
              <img 
                :src="selectedChat.sender_id === currentUser?.id ? selectedChat.receiver_avatar_url : selectedChat.sender_avatar_url" 
                class="w-10 h-10 rounded-full"
              />
              <div class="ml-3">
                <div class="font-medium">
                  {{ selectedChat.sender_id === currentUser?.id ? selectedChat.receiver_full_name : selectedChat.sender_full_name }}
                </div>
                <div class="text-sm text-gray-500">
                  @{{ selectedChat.sender_id === currentUser?.id ? selectedChat.receiver_username : selectedChat.sender_username }}
                </div>
              </div>
            </div>
          </div>
          
          <div class="flex-1 overflow-y-auto p-4" ref="messageContainer">
            <div v-if="messages.length === 0" class="flex items-center justify-center h-full text-gray-500">
              No messages yet
            </div>
            <template v-else>
              <div v-for="message in messages" :key="message.id" class="mb-4">
                <div class="flex items-start" :class="{'justify-end': message.sender_id === currentUser?.id}">
                  <div class="flex items-end gap-2">
                    <div class="order-2" v-if="message.sender_id !== currentUser?.id">
                      <img :src="message.sender.avatar_url || '/default-avatar.png'" class="w-8 h-8 rounded-full" />
                    </div>
                    <div 
                      class="max-w-md px-4 py-2 rounded-lg"
                      :class="message.sender_id === currentUser?.id ? 'bg-blue-500 text-white' : 'bg-gray-100'"
                    >
                      <div class="flex items-center justify-between gap-4">
                        <div>{{ message.content }}</div>
                        <button 
                          v-if="message.sender_id === currentUser?.id || message.receiver_id === currentUser?.id"
                          @click="deleteMessage(message)"
                          class="text-xs opacity-50 hover:opacity-100"
                        >
                          Delete
                        </button>
                      </div>
                      <div class="text-xs mt-1 opacity-50">
                        {{ formatDate(message.created_at) }}
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </template>
          </div>

          <div v-if="selectedChat" class="p-4 border-t border-gray-200">
            <form @submit.prevent="sendMessage" class="flex gap-2">
              <input
                v-model="newMessage"
                type="text"
                placeholder="Type a message..."
                class="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
              <button
                type="submit"
                class="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
              >
                Send
              </button>
            </form>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '../lib/supabase'
import Header from '../components/Header.vue'
import { formatDistanceToNow } from 'date-fns'

const route = useRoute()
const router = useRouter()
const currentUser = ref(null)
const conversations = ref([])
const messages = ref([])
const selectedChat = ref(null)
const newMessage = ref('')
const searchQuery = ref('')
const searchResults = ref([])
const showSearchResults = ref(false)
const messageContainer = ref(null)

// Format date
const formatDate = (date) => {
  return formatDistanceToNow(new Date(date), { addSuffix: true })
}

// Load conversations
const loadConversations = async () => {
  const { data: { user } } = await supabase.auth.getUser()
  currentUser.value = user

  const { data, error } = await supabase
    .from('messages_participants')
    .select('*')
    .order('created_at', { ascending: false })

  if (error) {
    console.error('Error loading conversations:', error)
    return
  }

  conversations.value = data
}

// Load messages for selected chat
const loadMessages = async () => {
  if (!selectedChat.value) return

  const otherId = selectedChat.value.sender_id === currentUser.value?.id 
    ? selectedChat.value.receiver_id 
    : selectedChat.value.sender_id

  const { data, error } = await supabase
    .from('messages')
    .select(`
      *,
      sender:profiles!messages_sender_id_fkey(username, full_name, avatar_url),
      receiver:profiles!messages_receiver_id_fkey(username, full_name, avatar_url)
    `)
    .or(`and(sender_id.eq.${currentUser.value?.id},receiver_id.eq.${otherId}),and(sender_id.eq.${otherId},receiver_id.eq.${currentUser.value?.id})`)
    .order('created_at', { ascending: true })

  if (error) {
    console.error('Error loading messages:', error)
    return
  }

  messages.value = data

  // Mark messages as read
  await supabase
    .from('messages')
    .update({ is_read: true })
    .eq('receiver_id', currentUser.value?.id)
    .eq('is_read', false)

  // Scroll to bottom
  setTimeout(() => {
    if (messageContainer.value) {
      messageContainer.value.scrollTop = messageContainer.value.scrollHeight
    }
  }, 100)
}

// Send message
const sendMessage = async () => {
  if (!newMessage.value.trim() || !selectedChat.value) return

  const otherId = selectedChat.value.sender_id === currentUser.value?.id 
    ? selectedChat.value.receiver_id 
    : selectedChat.value.sender_id

  const { error } = await supabase
    .from('messages')
    .insert({
      sender_id: currentUser.value?.id,
      receiver_id: otherId,
      content: newMessage.value.trim()
    })

  if (error) {
    console.error('Error sending message:', error)
    return
  }

  newMessage.value = ''
}

// Delete message
const deleteMessage = async (message) => {
  const { error } = await supabase
    .rpc('soft_delete_message', {
      message_id: message.id,
      user_id: currentUser.value?.id
    })

  if (error) {
    console.error('Error deleting message:', error)
  }
}

// Search users
const handleSearch = async () => {
  if (!searchQuery.value.trim()) {
    searchResults.value = []
    showSearchResults.value = false
    return
  }

  const { data, error } = await supabase
    .from('profiles')
    .select('*')
    .or(`username.ilike.%${searchQuery.value}%,full_name.ilike.%${searchQuery.value}%`)
    .limit(5)

  if (error) {
    console.error('Error searching users:', error)
    return
  }

  searchResults.value = data
  showSearchResults.value = true
}

// Start chat with user
const startChat = async (user) => {
  searchQuery.value = ''
  searchResults.value = []
  showSearchResults.value = false

  // Check if chat exists
  const { data } = await supabase
    .from('messages')
    .select('*')
    .or(`and(sender_id.eq.${currentUser.value?.id},receiver_id.eq.${user.id}),and(sender_id.eq.${user.id},receiver_id.eq.${currentUser.value?.id})`)
    .order('created_at', { ascending: false })
    .limit(1)
    .single()

  if (data) {
    selectedChat.value = {
      ...data,
      receiver_id: user.id,
      receiver_username: user.username,
      receiver_full_name: user.full_name,
      receiver_avatar_url: user.avatar_url
    }
  } else {
    selectedChat.value = {
      sender_id: currentUser.value?.id,
      receiver_id: user.id,
      receiver_username: user.username,
      receiver_full_name: user.full_name,
      receiver_avatar_url: user.avatar_url
    }
  }

  await loadMessages()
}

// Select chat
const selectChat = async (chat) => {
  selectedChat.value = chat
  await loadMessages()
}

// Set up realtime subscriptions
let messagesSubscription
let conversationsSubscription

onMounted(async () => {
  await loadConversations()

  // Subscribe to new messages
  messagesSubscription = supabase
    .channel('messages')
    .on('postgres_changes', {
      event: '*', // Listen to all events (INSERT, UPDATE, DELETE)
      schema: 'public',
      table: 'messages',
      filter: `sender_id=eq.${currentUser.value?.id} OR receiver_id=eq.${currentUser.value?.id}`
    }, (payload) => {
      console.log('Realtime message:', payload)
      
      // Handle different events
      if (payload.eventType === 'INSERT') {
        // If we're in the chat where this message belongs, add it to messages
        if (selectedChat.value) {
          const otherId = selectedChat.value.sender_id === currentUser.value?.id 
            ? selectedChat.value.receiver_id 
            : selectedChat.value.sender_id
          
          if (payload.new.sender_id === otherId || payload.new.receiver_id === otherId) {
            loadMessages() // Reload messages to get the full message data with sender/receiver info
          }
        }
        // Always reload conversations to update the latest message
        loadConversations()
      } 
      else if (payload.eventType === 'UPDATE') {
        // Update message in the list if it exists
        if (selectedChat.value) {
          const index = messages.value.findIndex(m => m.id === payload.new.id)
          if (index !== -1) {
            messages.value[index] = {
              ...messages.value[index],
              ...payload.new
            }
          }
        }
        // Reload conversations if is_read status changed
        if (payload.old.is_read !== payload.new.is_read) {
          loadConversations()
        }
      }
      else if (payload.eventType === 'DELETE') {
        // Remove message from the list if it exists
        if (selectedChat.value) {
          messages.value = messages.value.filter(m => m.id !== payload.old.id)
        }
        loadConversations() // Reload conversations to update the latest message
      }
    })
    .subscribe()

  // If user_id is provided in route, start chat with that user
  if (route.query.user_id) {
    const { data: user } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', route.query.user_id)
      .single()

    if (user) {
      await startChat(user)
    }
  }
})

onUnmounted(() => {
  if (messagesSubscription) {
    supabase.removeChannel(messagesSubscription)
  }
})
</script>