import React, { useEffect, useState } from 'react';
import ReactQuill from 'react-quill';
import { Edit, Save } from "lucide-react";
import 'react-quill/dist/quill.snow.css';
import './styles.css';

type DocumentHeaderInfo = {
    title?: string;
    subtitle?: string;
    image?: string;
    leftInfo: string[];
    rightInfo: string[];
}

export type Document = {
    header: DocumentHeaderInfo;
    subContent: {
        label: string;
    }[];
    enableContent: boolean;
    content: string;
}

type DocumentInfo = {
    id: any;
    onDocumentSave?: (content: string) => void;
}

function DocumentHeader({ dark, headerInfo, scale }: { dark: boolean, headerInfo: DocumentHeaderInfo, scale: number }) {
    return (
        <div className="flex flex-col items-center gap-10 w-full select-none">
            {headerInfo.title && <h1 className={`text-2xl font-bold ${dark ? "text-white" : "text-black"}`} style={{ fontSize: `${scale * 24}px` }}>{headerInfo.title}</h1>}
            <div className="relative w-full">
            {headerInfo.image && <img src={headerInfo.image} alt="Logo" className="absolute w-24 h-24 left-[50%] translate-x-[-50%] top-[50%] translate-y-[-50%] pointer-events-none" draggable={false} style={{ width: `${scale * 100}px`, height: `${scale * 100}px` }} />}
            <div className="flex flex-row items-center justify-between w-full">
                <div className="flex flex-col">
                    {headerInfo.leftInfo.map((info: string, index: number) => (
                        <p key={index} className={`text-sm font-semibold ${dark ? "text-white" : "text-black"}`} style={{ fontSize: `${scale * 16}px` }} dangerouslySetInnerHTML={{ __html: info }} />
                    ))}
                </div>
                <div className="flex flex-col items-end">
                    {headerInfo.rightInfo.map((info: string, index: number) => (
                        <p key={index} className="text-sm font-semibold" style={{ fontSize: `${scale * 16}px` }} dangerouslySetInnerHTML={{ __html: info }} />
                    ))}
                </div>
            </div>
            </div>
            {headerInfo.subtitle ?
             <h2 className={`text-lg font-bold ${dark ? "text-white" : "text-black"}`} style={{ fontSize: `${scale * 24}px` }}>{headerInfo.subtitle}</h2>
            : <div className="h-[0px]"></div>}
        </div>
    );
}

export function Document({dark, width, height, canEdit, headerInfo, initialContent, onDocumentSave}: { dark: boolean, width?: number, height?: number, canEdit: boolean, headerInfo?: DocumentHeaderInfo, initialContent: string, onDocumentSave?: (content: string) => void
    
}) {
    const [content, setContent] = useState<string>(initialContent);
    const [editing, setEditing] = useState(false);
    return (
        <div className="flex flex-col p-10 relative" style={{
            width: `${width || 600}px`,
            height: `${height || 774}px`,
            backgroundImage: 'url(/nui/images/paper.png)',
            backgroundRepeat: 'no-repeat',
            backgroundSize: 'cover',
            backgroundPosition: 'center',
            overflowY: 'auto',
            color: !dark ? "white" : "black",
        }}>
            {canEdit && (
                !editing ? (<Edit className="absolute top-4 right-4 cursor-pointer" onClick={() => setEditing(!editing)} />) : (
                <Save className="absolute top-4 right-4 cursor-pointer" onClick={() => {
                    if (editing && onDocumentSave) {
                        onDocumentSave(content);
                    }
                    setEditing(!editing);
                }} />
            ))}
            <div style={{ paddingBottom: editing ? "14px" : "0px" }}>
                {headerInfo && <DocumentHeader scale={(width || 600) / 600} dark={!dark} headerInfo={headerInfo} />}
            </div>
            <div style={{ backgroundColor: editing ? "white" : "transparent" }}>
                {editing ? (
                    <ReactQuill 
                        theme="snow" 
                        value={content} 
                        onChange={(value) => setContent(value)}
                        readOnly={!editing}
                        modules={{
                            toolbar: [
                                [{ 'header': [1, 2, 3, 4, 5, 6, false] }],
                                [{ 'font': [] }],
                                [{ 'size': ['small', false, 'large', 'huge'] }],
                                ['bold', 'italic', 'underline', 'strike'],
                                [{ 'color': [] }, { 'background': [] }],
                                [{ 'script': 'sub'}, { 'script': 'super' }],
                                ['blockquote', 'code-block'],
                                [{ 'list': 'ordered'}, { 'list': 'bullet' }],
                                [{ 'indent': '-1'}, { 'indent': '+1' }],
                                [{ 'direction': 'rtl' }],
                                [{ 'align': [] }],
                                ['link', 'image', 'video'],
                                ['clean']
                            ]
                        }}
                    />
                ) : (
                    <>
                    <span></span>
                    <ReactQuill 
                        className="active"
                        theme="snow"
                        value={content} 
                        readOnly={true}
                        modules={{
                            toolbar: null
                        }}
                    />
                    </>
                )}
            </div>
        </div>
    );
}

export function DocumentDisplay({documentInfo, width, height, dark, canEdit}: {documentInfo: DocumentInfo, width?: number, height?: number, dark: boolean, canEdit: boolean}) {
    const [document, setDocument] = useState<Document | null>(null);
    useEffect(() => {
        const thread = async () => {
            setDocument(documentInfo as unknown as Document);
        }
        thread();
    }, [documentInfo]);
    return (
        <div className="w-full h-full relative" style={{
            width: `${width || 600}px`,
            height: `${height || 774}px`,
        }}>
            {document ? (
                <Document onDocumentSave={documentInfo.onDocumentSave || undefined} dark={dark} width={width} height={height} canEdit={canEdit} headerInfo={document.header} initialContent={document.content} />
            ) : (
                <div className="w-full h-full flex items-center justify-center">
                    <div className="text-sm text-muted-foreground">
                        Loading...
                    </div>
                </div>
            )}
        </div>
    );
}

export default function DocumentContainer({document}: {document: Document}) {
    return (
        <div className="w-screen h-screen absolute text-primary top-0 left-0 bg-gray-900 flex items-center justify-center">
            {/* <Document canEdit={true} headerInfo={document.header} initialContent={document.content} /> */}
        </div>
    );
}