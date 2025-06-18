// import { useState } from "react";
// import EditorComponent from "./EditorComponent";
// import { Edit, Save } from "lucide-react";

// function DocumentHeader({ headerInfo }: { headerInfo: DocumentHeaderInfo }) {
//     return (
//         <div className="flex flex-col items-center gap-10 w-full select-none">
//             {headerInfo.title && <h1 className="text-2xl font-bold">{headerInfo.title}</h1>}
//             <div className="relative w-full">
//             {headerInfo.image && <img src={headerInfo.image} alt="Logo" className="absolute w-24 h-24 left-[50%] translate-x-[-50%] top-[50%] translate-y-[-50%] pointer-events-none" draggable={false} />}
//             <div className="flex flex-row items-center justify-between w-full">
//                 <div className="flex flex-col">
//                     {headerInfo.leftInfo.map((info, index) => (
//                         <p key={index} className="text-sm font-semibold" dangerouslySetInnerHTML={{ __html: info.label }} />
//                     ))}
//                 </div>
//                 <div className="flex flex-col items-end">
//                     {headerInfo.rightInfo.map((info, index) => (
//                         <p key={index} className="text-sm font-semibold" dangerouslySetInnerHTML={{ __html: info.label }} />
//                     ))}
//                 </div>
//             </div>
//             </div>
//             {headerInfo.subtitle && <h2 className="text-lg font-bold">{headerInfo.subtitle}</h2>}
//         </div>
//     );
// }
// function Document({canEdit, headerInfo, initialContent}: { canEdit: boolean, headerInfo?: DocumentHeaderInfo, initialContent: string }) {
//     let currentValue: string | undefined = undefined;
//     const [content, setContent] = useState<string>(initialContent);
//     const [editing, setEditing] = useState(false);
//     console.log(content)
//     return (
//         <div className="flex flex-col w-[600px] h-[774px] p-10 relative" style={{
//             backgroundImage: 'url(/nui/images/paper.png)',
//             backgroundRepeat: 'no-repeat',
//             backgroundSize: 'cover',
//             backgroundPosition: 'center',
//             overflowY: 'auto',
//         }}>
//             {canEdit && (
//                 !editing ? (<Edit className="absolute top-4 right-4 cursor-pointer" onClick={() => setEditing(!editing)} />) : (
//                 <Save className="absolute top-4 right-4 cursor-pointer" onClick={() => {
//                     if (currentValue !== undefined) {
//                         setContent(currentValue);
//                     }
//                     setEditing(!editing)
//                 }} />
//             ))}
//             <div style={{ paddingBottom: editing ? "14px" : "0px" }}>
//                 {headerInfo && <DocumentHeader headerInfo={headerInfo} />}
//             </div>
//             <EditorComponent defaultContent={content} config={{
//                 toolbar: editing,
//                 readonly: !editing,
//             }} onBlur={(newContent: string) => {
//                 setContent(newContent);
//                 currentValue = newContent;
//             }} onChange={(newContent: string) => {
//                 currentValue = newContent;
//             }} />
//         </div>
//     );
// }

// type DocumentInfo = {
//     title: string;
//     subtitle: string;
//     header: {
//         showImage: boolean;
//         leftInfo: {
//             label: string;
//         }[];
//         rightInfo: {
//             label: string;
//         }[];
//     };
//     subContent: {
//         label: string;
//     }[];
//     enableContent: boolean;
//     content: string;
// }

// export default function DocumentContainer() {
//     const [document, setDocument] = useState<DocumentInfo>({
//         title: "{department}",
//         subtitle: "SHIFT REPORT",
//         header: {
//             showImage: true,
//             leftInfo: [
//                 { label: "<span class='font-bold'>Pickle Rick</span>"},
//                 { label: "Chief of Police"},
//             ],
//             rightInfo: [
//                 { label: "<span class='font-bold'>Shift Start</span>"},
//                 { label: "01/01/2000 12:41 PM"},
//                 { label: "<span class='font-bold'>Shift End</span>"},
//                 { label: "01/01/2000 12:41 PM"},
//             ],
//         },
//         subContent: [
//             { label: "<span class='font-bold'>{name}</span>" },
//             { label: "{rank}" },
//         ],
//         enableContent: true,
//         content: "<p>Write your document here...</p>",
//     });
//     return (
//         <div className="w-screen h-screen absolute text-primary top-0 left-0 bg-gray-900 flex items-center justify-center">
//             <Document canEdit={true} headerInfo={headerInfo} initialContent={"<p>Write your document here...</p>"} />
//         </div>
//     );
// }

export default function DocumentContainer() {
    return (<></>)
}