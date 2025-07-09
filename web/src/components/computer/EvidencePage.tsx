import { useEffect, useState } from "react";
import Table from "../table/Table";
import { EyeIcon, FileIcon, FilesIcon, Plus, X } from "lucide-react";
import { Button } from "../ui/button";
import { useComputer } from "./Computer";
import { Translate } from "@/providers/locale/Locale";
import { ItemDisplay } from "../armory/Armory";

export type InventoryItem = {
    name: string;
    metadata?: any;
    count: number;
}

type File = {
    name: string;
    documentId: string;
    datetime: number;
    items?: InventoryItem[];
}

function SelectedFileModal({ file, onClose, isModalVisible }: { file: File, onClose: () => void, isModalVisible: boolean }) {
    const { openWindow } = useComputer();
    if (!file) return null;
    return (
        <div className={`absolute inset-0 bg-background/50 backdrop-blur-sm z-[50] flex items-center justify-center transition-opacity duration-200 ${isModalVisible ? 'opacity-100' : 'opacity-0'}`}>
            <div className={`bg-background/95 w-[75%] h-[75%] shadow-lg transition-all duration-200 ${isModalVisible ? 'scale-100 opacity-100' : 'scale-95 opacity-0'}`}>
                <div className="relative w-full h-[30px] bg-secondary flex items-center justify-between select-none ">
                    <div className="flex items-center justify-center gap-2 pl-2">
                        <div className="font-semibold text-sm text-white">{file.name}</div>
                    </div>
                    <div className="flex items-center justify-center gap-2 hover:bg-destructive/50 transition-all duration-300 h-[30px] w-[30px] cursor-pointer" onClick={onClose}>
                        <X/>
                    </div>
                </div>
                <div className="w-full h-full flex flex-col gap-2 p-2">
                    <div className="font-semibold text-sm px-2"><Translate id="items" />:</div>
                    <div className="grid grid-cols-6 gap-2 overflow-y-auto max-h-[250px] px-2">
                        <div className="relative bg-secondary/25 rounded-md p-1 group w-full h-full flex items-center justify-center hover:bg-secondary/50 transition-all duration-300 cursor-pointer">
                            <Plus className="w-8 h-8"/>
                        </div>
                        {file.items?.map((item: any, index: number) => {
                            return (
                                <div key={index} className="relative bg-secondary/25 rounded-md p-1 group w-fit">
                                    <ItemDisplay item={item} />
                                </div>
                            );
                        })}
                    </div>
                    <div className="w-full p-2 flex flex-row gap-2 items-center justify-center bg-green-600 rounded-md hover:bg-green-700 transition-all duration-300 cursor-pointer" onClick={() => {
                            openWindow("file", {id: file.documentId})
                        }}>
                        <FilesIcon className="w-4 h-4"/>
                        <div className="font-semibold text-sm"><Translate id="view_document" /></div>
                    </div>
                </div>
            </div>
        </div>
    )
}

export default function EvidencePage({ data }: { data?: any }) {
    const [files, setFiles] = useState<File[] | null>(null);
    const [selectedFile, setSelectedFile] = useState<File | null>(null);
    const [isModalVisible, setIsModalVisible] = useState(false);
    useEffect(() => {
        const thread = async () => {
            setTimeout(() => {
                setFiles([{ name: "Test", documentId: "1234", datetime: Date.now(), items: [
                    { name: "Test", count: 1 }, 
                    { name: "Test2", count: 2 },
                ] }]);
            }, 0);
        }
        thread();
    }, []);
    const handleFileSelect = (file: File) => {
        setSelectedFile(file);
        setTimeout(() => {
            setIsModalVisible(true);
        }, 10);
    };

    const handleFileDeselect = () => {
        setIsModalVisible(false);
        setTimeout(() => {
            setSelectedFile(null);
        }, 200);
    };
    return (
        <div className="relative h-full flex flex-col gap-0">
            {(selectedFile) && (
                <SelectedFileModal file={selectedFile} onClose={handleFileDeselect} isModalVisible={isModalVisible} />
            )}
            <div className="p-2">
                <div className="w-full flex flex-col gap-0 bg-secondary rounded-md p-1">
                    <input type="text" placeholder="Search" className="w-full h-[30px] bg-background/50 rounded-md p-2" />
                </div>
            </div>
            {files ? (
                <Table data={files.map(file => ({
                    ...file,
                    date: new Date(file.datetime).toLocaleString(),
                    action: (
                        <Button variant="outline" size="icon" onClick={() => handleFileSelect(file)}>
                            <EyeIcon className="w-4 h-4"/>
                        </Button>
                    ),
                }))} columns={[{
                    key: "name",
                    header: "Name",
                }, {
                    key: "date",
                    header: "Date",
                }, {
                    key: "action",
                    header: "",
                },]} />
            ) : (
                <div className="w-full h-full flex items-center justify-center">
                    <div className="text-sm text-muted-foreground">
                        Loading...
                    </div>
                </div>
            )}
        </div>
    )
}