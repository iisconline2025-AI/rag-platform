interface ChatLayoutProps {
  conversationId?: string;
  children?: React.ReactNode;
}

export default function ChatLayout({ conversationId, children }: ChatLayoutProps) {
  return (
    <div className="flex h-screen overflow-hidden bg-slate-50">
      <aside className="hidden w-60 shrink-0 flex-col border-r border-slate-200 bg-white md:flex">
        <div className="flex h-16 shrink-0 items-center border-b border-slate-100 px-6">
          <span className="text-sm font-semibold tracking-wide text-indigo-600">Chat</span>
        </div>
        <div className="flex-1 overflow-y-auto px-4 py-4 text-xs text-slate-400">
          Conversations placeholder
        </div>
      </aside>

      <main className="flex flex-1 flex-col overflow-y-auto">
        {children ?? (
          <div className="flex flex-1 items-center justify-center text-sm text-slate-400">
            {conversationId ? `Conversation ${conversationId} placeholder` : 'New chat placeholder'}
          </div>
        )}
      </main>
    </div>
  );
}
