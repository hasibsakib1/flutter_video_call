// ICE server configuration used by RTCPeerConnection
const defaultIceServers = [
  {
    'urls': 'stun:stun.l.google.com:19302',
  },
];

// You can add TURN servers here when needed for NAT traversal:
// { 'urls': 'turn:turn.example.com:3478', 'username': 'user', 'credential': 'pass' }
