import { useConfig } from "@/providers/config";
import { Translate } from "@/providers/locale/Locale";

export default function HomePage() {
    const { config } = useConfig();
    
    // Mock data - in a real app, this would come from props or API
    const latestNews = [
        {
            id: 1,
            title: "New Vehicle Models Added",
            content: "We've added several new vehicle models to the garage. Check them out!",
            date: "2024-01-15",
            author: "Admin"
        },
        {
            id: 2,
            title: "System Maintenance",
            content: "Scheduled maintenance will occur on January 20th at 2 AM.",
            date: "2024-01-14",
            author: "System"
        }
    ];

    const pinnedAnnouncement = {
        id: 1,
        title: "Important: New Security Protocol",
        content: "All officers must complete the new security training by the end of the month.",
        date: new Date(),
        author: "Chief",
        isPinned: true
    };

    return (
        <div className="w-full h-full p-6 overflow-y-auto">
            <div className="max-w-4xl mx-auto space-y-6">
                {pinnedAnnouncement && (
                    <div className="bg-yellow-300 border-l-4 border-yellow-400 p-4 rounded-md">
                        <h3 className="text-lg font-semibold text-yellow-900">
                            {pinnedAnnouncement.title}
                        </h3>
                        <p className="text-yellow-800 mb-1">{pinnedAnnouncement.content}</p>
                        <div className="flex items-center text-sm text-yellow-700">
                            <span>- {pinnedAnnouncement.author} {pinnedAnnouncement.date.toLocaleDateString()} @ {pinnedAnnouncement.date.toLocaleTimeString([], {hour: '2-digit', minute: '2-digit'})}</span>
                        </div>
                    </div>
                )}

                {/* Latest News Section */}
                <div className="rounded-lg bg-secondary p-6">
                    <h2 className="text-xl font-semibold text-white mb-4 flex items-center gap-2">
                        <svg className="w-5 h-5 text-blue-400" fill="currentColor" viewBox="0 0 20 20">
                            <path fillRule="evenodd" d="M2 5a2 2 0 012-2h8a2 2 0 012 2v10a2 2 0 002 2H4a2 2 0 01-2-2V5zm3 2h6v4H5V7zm6 6h4v2h-4v-2z" clipRule="evenodd" />
                        </svg>
                        Latest News
                    </h2>
                    
                    <div className="space-y-4">
                        {latestNews.map((news) => (
                            <div key={news.id} className="border-b border-gray-600 pb-4 last:border-b-0">
                                <div className="flex items-start justify-between mb-2">
                                    <h3 className="text-lg font-medium text-white">
                                        {news.title}
                                    </h3>
                                    <span className="text-sm text-gray-400">{news.date}</span>
                                </div>
                                <p className="text-gray-300 mb-2">{news.content}</p>
                                <div className="text-sm text-gray-400">
                                    By {news.author}
                                </div>
                            </div>
                        ))}
                    </div>
                </div>

                {/* Quick Actions */}
                <div className="rounded-lg shadow-md p-6">
                    <h2 className="text-xl font-semibold text-white mb-4">Quick Actions</h2>
                    <div className="grid grid-cols-2 gap-4">
                        <button className="p-4 text-left border border-gray-600 rounded-lg hover:bg-gray-800 transition-colors">
                            <div className="font-medium text-white">View Roster</div>
                            <div className="text-sm text-gray-400">Check department personnel</div>
                        </button>
                        <button className="p-4 text-left border border-gray-600 rounded-lg hover:bg-gray-800 transition-colors">
                            <div className="font-medium text-white">Evidence Log</div>
                            <div className="text-sm text-gray-400">Access evidence database</div>
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
}
