import { useState } from "react";
import EditorComponent from "./EditorComponent";
import { Edit, Save } from "lucide-react";

type DocumentHeaderInfo = {
    title?: string;
    image?: string;
    date?: number;
    address?: string;
    author: string;
    authorOccupation?: string;
}

function DocumentHeader({ headerInfo }: { headerInfo: DocumentHeaderInfo }) {
    return (
        <div className="flex flex-col items-center gap-10 w-full pb-8 select-none">
            {headerInfo.title && <h1 className="text-2xl font-bold">{headerInfo.title}</h1>}
            <div className="relative w-full">
            {headerInfo.image && <img src={headerInfo.image} alt="Logo" className="absolute w-24 h-24 left-[50%] translate-x-[-50%] top-[50%] translate-y-[-50%] pointer-events-none" draggable={false} />}
            <div className="flex flex-row justify-between w-full">
                <div className="flex flex-col">
                <p className="text-md font-bold">{headerInfo.author}</p>
                <p className="text-sm font-semibold">{headerInfo.authorOccupation}</p>
                </div>
                <div className="flex flex-col items-start">
                <p className="text-sm font-semibold">{new Date(headerInfo.date || Date.now()).toLocaleDateString()}</p>
                {headerInfo.address && <p className="text-sm font-semibold">{headerInfo.address}</p>}
                </div>
            </div>
            </div>
        </div>
    );
}
function Document({canEdit, headerInfo, initialContent}: { canEdit: boolean, headerInfo?: DocumentHeaderInfo, initialContent: string }) {
    let currentValue: string | undefined = undefined;
    const [content, setContent] = useState<string>(initialContent);
    const [editing, setEditing] = useState(false);
    console.log(content)
    return (
        <div className="flex flex-col w-[600px] h-[774px] p-10 relative" style={{
            backgroundImage: 'url(/nui/images/paper.png)',
            backgroundRepeat: 'no-repeat',
            backgroundSize: 'cover',
            backgroundPosition: 'center',
            overflowY: 'auto',
        }}>
            {canEdit && (
                !editing ? (<Edit className="absolute top-4 right-4 cursor-pointer" onClick={() => setEditing(!editing)} />) : (
                <Save className="absolute top-4 right-4 cursor-pointer" onClick={() => {
                    if (currentValue !== undefined) {
                        setContent(currentValue);
                    }
                    setEditing(!editing)
                }} />
            ))}
            {headerInfo && <DocumentHeader headerInfo={headerInfo} />}
            <EditorComponent defaultContent={content} config={{
                toolbar: editing,
                readonly: !editing,
            }} onBlur={(newContent: string) => {
                setContent(newContent);
                currentValue = newContent;
            }} onChange={(newContent: string) => {
                currentValue = newContent;
            }} />
        </div>
    );
}

export default function DocumentContainer() {
    const headerInfo: DocumentHeaderInfo = {
        title: "LOS SANTOS POLICE DEPARTMENT",
        image: "/nui/images/LSPD.webp",
        date: Date.now(),
        address: "1 Mission Row, Los Santos, SA",
        author: "Pickle Rick",
        authorOccupation: "Chief of Police"
    };
    return (
        <div className="w-screen h-screen absolute text-primary top-0 left-0 bg-gray-900 flex items-center justify-center">
            {/* <Document canEdit={true} headerInfo={headerInfo} initialContent={"<p>Write your document here...</p>"} /> */}
        </div>
    );
}