export default function ChatEmptyState() {
  return (
    <div className="flex flex-1 flex-col items-center justify-center px-6 text-center">
      <p className="text-sm font-medium text-slate-700">Ask a question about your knowledge base</p>
      <p className="mt-1 max-w-sm text-xs text-slate-400">
        Answers are grounded in your uploaded documents and include citations back to the source passages they
        were drawn from.
      </p>
    </div>
  );
}
