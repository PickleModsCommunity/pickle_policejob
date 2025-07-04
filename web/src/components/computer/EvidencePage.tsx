export default function EvidencePage({ data }: { data?: any }) {
    return (
        <div className="w-full h-full" style={{
            background: "red"
        }}>
            {data?.report}
        </div>
    )
}