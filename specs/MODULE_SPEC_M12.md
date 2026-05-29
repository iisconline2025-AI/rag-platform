# MODULE_SPEC_M12 — WhatsApp Bot Specialist

**Owner**: Member 12 | **Track**: Bot | **Branch**: `feat/whatsapp-bot`

## Role
Twilio WhatsApp sandbox end-to-end: receive message → parse → call RAG → TwiML reply. Phone → tenant mapping. Conversation memory.

## Day-by-Day Deliverables
| Day | Deliverable | Done? |
|---|---|---|
| 1 | Set up Twilio WhatsApp sandbox. Configure ngrok tunnel. Receive first test message. | ☐ |
| 2 | Wire Twilio → M4's `POST /webhooks/whatsapp`. Parse `Body` + `From`. | ☐ |
| 2 | Call M3's mock `/chat/query`. Format TwiML reply with answer. | ☐ |
| 3 | Real RAG reply: wire to real n8n retrieval (when M6 is ready) | ☐ |
| 4 | Phone → tenant routing working (different numbers → different knowledge bases) | ☐ |
| 5 | WhatsApp conversation memory: store messages in `chat_messages`, include history | ☐ |
| 5 | Live test with real phone + Twilio sandbox | ☐ |
| 6 | Polish TwiML format, handle long answers (truncate with "..." see full at URL) | ☐ |

## Files Owned
- `backend/app/bots/whatsapp.py`
- `backend/app/bots/tenant_map.py`

## Twilio Sandbox Setup
```
1. Go to https://www.twilio.com/console/messaging/whatsapp/sandbox
2. Note: sandbox number = whatsapp:+14155238886
3. Webhook URL = https://your-ngrok-url.ngrok.io/webhooks/whatsapp
4. Set in Twilio console under "When a message comes in"
5. Join sandbox: send "join <code>" from your WhatsApp to the sandbox number
```

## whatsapp.py Key Functions
```python
# backend/app/bots/whatsapp.py

async def handle_whatsapp_message(body: str, from_number: str) -> str:
    """Returns TwiML XML string"""
    tenant_id = await get_tenant_for_phone(from_number)
    if not tenant_id:
        return twiml_reply("Sorry, your number is not registered. Please contact your administrator.")
    response = await n8n_client.retrieve(query=body, tenant_id=tenant_id)
    answer = response["answer"]
    sources = response.get("sources", [])[:2]
    source_text = ""
    if sources:
        source_text = "\n\n📚 Sources: " + ", ".join([f"{s['title']} p.{s.get('page_number','?')}" for s in sources])
    return twiml_reply(answer + source_text)

def twiml_reply(message: str) -> str:
    message = message[:1600]  # WhatsApp limit
    return f'<?xml version="1.0"?><Response><Message>{message}</Message></Response>'
```

## tenant_map.py
```python
# Maps WhatsApp phone numbers to tenant IDs
# Stored in whatsapp_tenant_map table (see ARCHITECTURE.md DB schema)

async def get_tenant_for_phone(phone_number: str) -> Optional[str]:
    # SELECT tenant_id FROM whatsapp_tenant_map WHERE phone_number = $1
    ...

async def register_phone_for_tenant(phone_number: str, tenant_id: str):
    # INSERT INTO whatsapp_tenant_map (phone_number, tenant_id) VALUES ($1, $2)
    # Admin does this via /admin/settings page
    ...
```

## Conversation Memory
```python
# Before calling n8n retrieve:
# 1. Load last 10 messages for this phone number from chat_messages
# 2. Include as conversation_history in retrieve request
# After getting response:
# 3. Save user message + assistant response to chat_messages
```

## Acceptance Criteria
- [ ] Send WhatsApp message to sandbox → receive grounded answer in < 15 seconds
- [ ] Different phone numbers → different tenant knowledge bases
- [ ] Unknown phone number → friendly registration message
- [ ] Conversation history included in context (test with multi-turn conversation)
- [ ] Long answers truncated to 1600 chars for WhatsApp
- [ ] Twilio signature validation active (Day 5)
