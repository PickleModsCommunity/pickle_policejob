import { useEffect, useState } from "react";
import Table from "../table/Table";
import { EyeIcon, FileIcon, FilePlusIcon, FilesIcon, Loader2, Plus, PlusIcon, Printer, SaveIcon, Trash, X } from "lucide-react";
import { Button } from "../ui/button";
import { useComputer } from "./Computer";
import { Translate } from "@/providers/locale/Locale";
import { ItemDisplay } from "../armory/Armory";
import { fetchNui } from "@/providers/nui/fetchNui";
import { Document } from "../document/Document";
import { useNuiEvent } from "@/providers/nui/useNui";

export type InventoryItem = {
    name: string;
    metadata?: any;
    count: number;
}

export type Evidence = {
    type: string;
    identifier: string;
    time?: number;
    label: string;
    heading: number;
    coords: {
        x: number;
        y: number;
        z: number;
    };
    image: string;
    direction?: {
        x: number;
        y: number;
        z: number;
    };
    amount?: number;
    weaponGroup?: string;
    weaponHash?: number;
    explosionType?: number;
    plate?: string;
    seats?: Record<string, {
        time: number;
        identifier: string;
    }>;
    origin?: {
        x: number;
        y: number;
        z: number;
    };
    bac?: number;
    name?: string;
    serial?: string;
    result?: string;
    results?: Record<string, number | string>;
}

export type EvidenceItems = {
    name: string;
    evidence: Evidence[];
    slot: number;
}

export type File = {
    id: number;
    name: string;
    authorIdentifier: string;
    datetime: number;
    evidence: Evidence[];
    document: Document;
}

function EvidenceImage({ evidence }: { evidence: Evidence }) {
    const [loaded, setLoaded] = useState(false);
    return (
        <div className="relative rounded-sm bg-background w-full aspect-video">
            {!loaded && (
                <div className="absolute inset-0 flex items-center justify-center">
                    <div className="w-8 h-8 border-4 border-white border-t-transparent rounded-full animate-spin"></div>
                </div>
            )}
            <img 
            src={evidence.image} 
            alt={evidence.label} 
            className="w-full h-full object-contain rounded-sm" 
            onLoad={() => setLoaded(true)}
            />
        </div>
    )
}

export function EvidenceDisplay({ evidence, index }: { evidence: Evidence, index?: number }) {
    return (
        <div className="relative flex flex-col justify-center items-center select-none w-full">
            <div className="w-full" style={{aspectRatio: "16/9"}}>
                <EvidenceImage evidence={evidence} />
            </div>
            {(index !== undefined) && (
                <div className="absolute top-0 left-0 bg-background/95 rounded-br-sm h-[20px] font-semibold text-xs text-white flex items-center px-1">
                    #{index + 1}
                </div>
            )}
            <div className="absolute bottom-[-1px] left-0 w-full h-[24px] bg-background/95 rounded-b-sm font-semibold text-xs text-white flex items-center px-2">
                {evidence.label}
            </div>
        </div>
    )
}

function GetVectorDistance(vector1: { x: number, y: number, z: number }, vector2: { x: number, y: number, z: number }) {
    return Math.sqrt(Math.pow(vector1.x - vector2.x, 2) + Math.pow(vector1.y - vector2.y, 2) + Math.pow(vector1.z - vector2.z, 2));
}

export function SelectedEvidenceModal({ evidence, onClose, isModalVisible }: { evidence: Evidence, onClose: () => void, isModalVisible: boolean }) {
    return (
        <div className={`absolute inset-0 bg-background/50 backdrop-blur-sm z-[50] flex items-center justify-center transition-opacity duration-200 ${isModalVisible ? 'opacity-100' : 'opacity-0'}`}>
            <div className={`bg-background w-[90%] max-h-[90%] shadow-lg transition-all duration-200 ${isModalVisible ? 'scale-100 opacity-100' : 'scale-95 opacity-0'}`}>
                <div className="relative w-full h-[30px] bg-secondary flex items-center justify-between select-none ">
                    <div className="flex items-center justify-center gap-2 pl-2">
                        <div className="font-semibold text-sm text-white">{evidence.label}</div>
                    </div>
                    <div className="flex items-center justify-center gap-2 hover:bg-destructive/50 transition-all duration-300 h-[30px] w-[30px] cursor-pointer" onClick={onClose}>
                        <X/>
                    </div>
                </div>
                <div className="flex flex-col gap-2 p-2">
                    <div className="grid grid-cols-2 gap-2 w-full justify-between">
                        <EvidenceImage evidence={evidence} />
                        <div className="flex flex-col gap-2">
                            {evidence.identifier && (
                                <div className="flex flex-row items-center gap-2">
                                    <div className="font-semibold text-sm text-white"><Translate id="evidence_identifier" />:</div>
                                    <div className="text-xs text-white">{evidence.identifier}</div>
                                </div>
                            )}
                            {evidence.time && (
                                <div className="flex flex-row items-center gap-2">
                                    <div className="font-semibold text-sm text-white"><Translate id="evidence_time" />:</div>
                                    <div className="text-xs text-white">{new Date(evidence.time * 1000).toLocaleString()}</div>
                                </div>
                            )}
                            {evidence.coords && (
                                <div className="flex flex-row items-center gap-2">
                                    <div className="font-semibold text-sm text-white"><Translate id="evidence_coords" />:</div>
                                    <div className="text-xs text-white">{Math.round(evidence.coords.x * 100) / 100}, {Math.round(evidence.coords.y * 100) / 100}, {Math.round(evidence.coords.z * 100) / 100} ({evidence.heading.toFixed(2)}°)</div>
                                </div>
                            )}
                            {evidence.direction && (
                                <>
                                    <div className="flex flex-row items-center gap-2">
                                        <div className="font-semibold text-sm text-white"><Translate id="evidence_direction" />:</div>
                                        <div className="text-xs text-white">{Math.round(evidence.direction.x * 100) / 100}, {Math.round(evidence.direction.y * 100) / 100}, {Math.round(evidence.direction.z * 100) / 100}</div>
                                    </div>
                                    <div className="flex flex-row items-center gap-2">
                                        <div className="font-semibold text-sm text-white"><Translate id="evidence_distance" />:</div>
                                        <div className="text-xs text-white">{Math.round(GetVectorDistance(evidence.coords, evidence.direction) * 100) / 100}m</div>
                                    </div>
                                </>
                            )}
                            {evidence.weaponGroup && (
                                <div className="flex flex-row items-center gap-2">
                                    <div className="font-semibold text-sm text-white"><Translate id="evidence_weapon_group" />:</div>
                                    <div className="text-xs text-white">{evidence.weaponGroup}</div>
                                </div>
                            )}
                            {evidence.amount && (
                                <div className="flex flex-row items-center gap-2">
                                    <div className="font-semibold text-sm text-white"><Translate id="evidence_amount" />:</div>
                                    <div className="text-xs text-white">{evidence.amount}</div>
                                </div>
                            )}
                            {evidence.explosionType && (
                                <div className="flex flex-row items-center gap-2">
                                    <div className="font-semibold text-sm text-white"><Translate id="evidence_explosion_type" />:</div>
                                    <div className="text-xs text-white">{evidence.explosionType}</div>
                                </div>
                            )}
                            {evidence.plate && (
                                <div className="flex flex-row items-center gap-2">
                                    <div className="font-semibold text-sm text-white"><Translate id="evidence_plate" />:</div>
                                    <div className="text-xs text-white">{evidence.plate}</div>
                                </div>
                            )}
                            {evidence.seats && (
                                Object.keys(evidence.seats).map((seat: string, index: number) => {
                                    return (
                                        <div className="flex flex-row items-center gap-2">
                                            <div className="font-semibold text-sm text-white"><Translate id="evidence_seat" args={[index + 2]} />:</div>
                                            <div className="text-xs text-white">{evidence.seats?.[seat]?.identifier} @ {new Date(evidence.seats?.[seat]?.time ?? 0).toLocaleString()}</div>
                                        </div>
                                    )
                                })
                            )}
                            {evidence.bac && (
                                <div className="flex flex-row items-center gap-2">
                                    <div className="font-semibold text-sm text-white"><Translate id="evidence_bac" />:</div>
                                    <div className="text-xs text-white">{evidence.bac.toFixed(2)}</div>
                                </div>
                            )}
                            {evidence.name && (
                                <div className="flex flex-row items-center gap-2">
                                    <div className="font-semibold text-sm text-white"><Translate id="evidence_name" />:</div>
                                    <div className="text-xs text-white">{evidence.name}</div>
                                </div>
                            )}
                            {evidence.serial && (
                                <div className="flex flex-row items-center gap-2">
                                    <div className="font-semibold text-sm text-white"><Translate id="serial" />:</div>
                                    <div className="text-xs text-white">{evidence.serial}</div>
                                </div>
                            )}
                            {evidence.result && (
                                <div className="flex flex-row items-center gap-2">
                                    <div className="font-semibold text-sm text-white"><Translate id="evidence_result" />:</div>
                                    <div className="text-xs text-white">{evidence.result}</div>
                                </div>
                            )}
                            {evidence.results && (
                                Object.keys(evidence.results).map((resultType: string, index: number) => {
                                    return (
                                        <div className="flex flex-row items-center gap-2">
                                            <div className="font-semibold text-sm text-white"><Translate id={resultType} />:</div>
                                            <div className="text-xs text-white">{evidence.results?.[resultType] || "-"}</div>
                                        </div>
                                    )
                                })
                            )}
                        </div>
                    </div>
                </div>
            </div>
        </div>
    )
}

function AddEvidenceModal({ isCreatingFile, onClose, importEvidence, isModalVisible }: { isCreatingFile?: boolean, onClose: () => void, importEvidence: (evidence: Evidence[]) => void, isModalVisible: boolean }) {
    const [evidenceItems, setEvidenceItems] = useState<EvidenceItems[] | null>(null);
    const [selectedEvidenceItem, setSelectedEvidenceItem] = useState<EvidenceItems | null>(null);
    const [selectedEvidence, setSelectedEvidence] = useState<Evidence | null>(null);
    const [isEvidenceVisible, setIsEvidenceVisible] = useState(false);
    const [isDeletingEvidenceItem, setIsDeletingEvidenceItem] = useState(false);
    useEffect(() => {
        const thread = async () => {
            fetchNui("getEvidenceItems", {isCreatingFile: isCreatingFile}).then((data: any) => {
                setEvidenceItems(data);
            });
            // setEvidenceItems([
            //     {
            //         name: "evidence_report",
            //         evidence: Array(10).fill(
            //             {
            //                 "type": "blood",
            //                 "identifier": "XLB21AB2",
            //                 "label": "Blood",
            //                 "heading": 0.0,
            //                 "coords": {
            //                     "x": -1293.3231201171876,
            //                     "y": -949.8065795898438,
            //                     "z": 10.3179931640625
            //                 },
            //                 "image": "https://r2.fivemanage.com/2OthvhJFCzp3qiOWIvKTq/DevF71SPFLoZ.jpg"
            //             }
            //         )
            //     },
            // ]);
        }
        thread();
    }, []);
    return (
        <div className={`absolute inset-0 bg-background/50 backdrop-blur-sm z-[50] flex items-center justify-center transition-opacity duration-200 ${isModalVisible ? 'opacity-100' : 'opacity-0'}`}>
            <div className={`bg-background w-[90%] h-[90%] relative shadow-lg transition-all duration-200 ${isModalVisible ? 'scale-100 opacity-100' : 'scale-95 opacity-0'}`}>
                <div className="relative w-full h-[30px] bg-secondary flex items-center justify-between select-none">
                    <div className="flex items-center justify-center gap-2 pl-2">
                        <div className="font-semibold text-sm text-white"><Translate id="add_evidence" /></div>
                    </div>
                    <div className="flex items-center justify-center gap-2 hover:bg-destructive/50 transition-all duration-300 h-[30px] w-[30px] cursor-pointer" onClick={onClose}>
                        <X/>
                    </div>
                </div>
                <div className="w-full h-[calc(100%-30px)] flex flex-col gap-2 relative">
                    {selectedEvidence && (
                        <SelectedEvidenceModal evidence={selectedEvidence} onClose={() => {
                            setIsEvidenceVisible(false);
                            setSelectedEvidence(null);
                        }} isModalVisible={isEvidenceVisible} />
                    )}
                    {!evidenceItems ? (
                        <div className="w-full h-full flex items-center justify-center">
                            <div className="text-sm text-muted-foreground">
                                <Loader2 className="w-8 h-8 animate-spin" />
                            </div>
                        </div>
                    ) : (
                        <div className="w-full h-full grid grid-cols-2 gap-0">
                            <div className="border-r-[1px] border-secondary overflow-y-auto p-2">
                                <div className="grid grid-cols-3 gap-2">
                                    {evidenceItems.map((evidenceItem: EvidenceItems, index: number) => {
                                        return (
                                            <div className="bg-secondary/50 w-24 h-24 rounded-md cursor-pointer" key={index} onClick={() => {
                                                setSelectedEvidenceItem(evidenceItem);
                                                setIsDeletingEvidenceItem(false);
                                            }}>
                                                <ItemDisplay item={{
                                                    name: evidenceItem.name,
                                                }} />
                                            </div>
                                        )
                                    })}
                                </div>
                            </div>
                            {!selectedEvidenceItem ? (
                                <div className="w-full h-full flex items-center justify-center">    
                                    <div className="text-sm text-muted-foreground">
                                        <Translate id="select_evidence_item" />
                                    </div>
                                </div>
                            ) : (
                                <div className="w-full h-full flex flex-col gap-2 p-2">
                                    <div className="grid grid-cols-2 gap-2 px-1 overflow-y-auto w-full max-h-[250px]">
                                        {selectedEvidenceItem.evidence?.map((evidence: Evidence, index: number) => {
                                            return (
                                                <div className="w-full cursor-pointer" onClick={() => {
                                                    setSelectedEvidence(evidence);
                                                    setTimeout(() => {
                                                        setIsEvidenceVisible(true);
                                                    }, 10);
                                                }}> 
                                                    <EvidenceDisplay evidence={evidence} index={index} />
                                                </div>
                                            );
                                        })}
                                    </div>
                                    <div className="w-full flex flex-row gap-2">
                                        <Button className="w-full" variant="outline" onClick={() => {
                                            importEvidence(selectedEvidenceItem.evidence);
                                            setIsDeletingEvidenceItem(false);
                                            setSelectedEvidenceItem(null);
                                            onClose();
                                        }}>
                                            <Translate id="import_evidence" />
                                        </Button>
                                        <Button size={"icon"} variant="outline" onClick={() => {
                                            if (isDeletingEvidenceItem) {
                                                setIsDeletingEvidenceItem(false);
                                                fetchNui("deleteEvidenceItem", {
                                                    name: selectedEvidenceItem.name,
                                                    slot: selectedEvidenceItem.slot,
                                                }).then((data: any) => {
                                                    setEvidenceItems(data);
                                                });
                                                setSelectedEvidenceItem(null);
                                            } else {    
                                                setIsDeletingEvidenceItem(true);
                                            }
                                        }}>
                                            {isDeletingEvidenceItem ? (
                                                <span><Trash/>?</span>
                                            ) : (
                                                <Trash/>
                                            )}
                                        </Button>
                                    </div>
                                </div>
                            )}
                        </div>
                    )}
                </div>
            </div>
        </div>
    )
}

function SelectedFileModal({ file, onClose, isModalVisible }: { file: File | null, onClose: () => void, isModalVisible: boolean }) {
    const { openWindow, closeWindow, department, player } = useComputer();
    const [selectedEvidence, setSelectedEvidence] = useState<Evidence | null>();
    const [isAddingEvidence, setIsAddingEvidence] = useState(false);
    const [isSubModalVisible, setIsSubModalVisible] = useState(false);
    const [fileName, setFileName] = useState<string>(file?.name || "Untitled File");
    const [fileEvidence, setFileEvidence] = useState<Evidence[]>(file?.evidence || []);
    const [documentWindowId, setDocumentWindowId] = useState<number | null>(null);
    const [documentContent, setDocumentContent] = useState<string | null>(file?.document ? file.document.content : null);
    const [deletingEvidenceId, setDeletingEvidenceId] = useState<number | null>(null);
    const fileAuthor = file?.authorIdentifier || player.identifier;
    const fileDate = file?.datetime || Date.now();
    const closeModal = () => {
        if (documentWindowId) {
            closeWindow(documentWindowId);
        }
        onClose();
    }
    const defaultDocument: Document = {
        header: {
            title: department.label.toUpperCase(),
            image: department.image,
            leftInfo: [`<b>${player.name}</b>`, `Los Santos, San Andreas`],
            rightInfo: [`<b>${department.ranks[0].label}</b>`, `${new Date(Date.now()).toLocaleString()}`],
        },
        subContent: [],
        enableContent: true,
        content: ""
    }
    return (
        <div className={`absolute inset-0 bg-background/50 backdrop-blur-sm z-[50] flex items-center justify-center transition-opacity duration-200 ${isModalVisible ? 'opacity-100' : 'opacity-0'}`}>
            <div className={`bg-background/95 w-[80%] h-[80%] shadow-lg transition-all duration-200 ${isModalVisible ? 'scale-100 opacity-100' : 'scale-95 opacity-0'}`}>
                <div className="relative w-full h-[30px] bg-secondary flex items-center justify-between select-none ">
                    <div className="flex items-center justify-center gap-2 pl-2">
                        <div className="font-semibold text-sm text-white">{fileName}</div>
                    </div>
                    <div className="flex items-center justify-center gap-2 hover:bg-destructive/50 transition-all duration-300 h-[30px] w-[30px] cursor-pointer" onClick={closeModal}>
                        <X/>
                    </div>
                </div>
                <div className="w-full flex flex-col p-2 gap-2 relative justify-between h-[calc(100%-30px)]">
                    <div className="w-full flex flex-col gap-2">
                        {!file && (
                            <div className="flex flex-row gap-2">
                                <div className="font-semibold text-sm text-white"><Translate id="filename" />:</div>
                                <input type="text" className="bg-secondary/50 rounded-md text-xs p-2 h-[20px]" value={fileName} onChange={(e) => {
                                    setFileName(e.target.value);
                                }} />
                            </div>
                        )}
                        <div className="grid grid-cols-4 gap-2 overflow-y-auto max-h-[250px] px-2">
                            <div className="cursor-pointer relative flex flex-col min-h-[92px] justify-center items-center w-full h-full bg-secondary/50 rounded-md" onClick={() => {
                                setIsAddingEvidence(true);
                                setTimeout(() => {
                                    setIsSubModalVisible(true);
                                }, 10);
                            }}>
                                <Plus className="w-6 h-6"/>
                            </div>
                            {fileEvidence.map((evidence: Evidence, index: number) => {
                                return (
                                    <div className="relative">
                                        <div className="absolute top-0 right-0 cursor-pointer z-10" onClick={() => {
                                            if (deletingEvidenceId === index) {
                                                setDeletingEvidenceId(null);
                                                setFileEvidence(prev => prev.filter((_, i) => i !== index));
                                                if (file) {
                                                    fetchNui("deleteEvidence", {
                                                        id: file.id,
                                                        index: index + 1,
                                                    });
                                                }
                                            } else {
                                                setDeletingEvidenceId(index);
                                            }
                                        }}>
                                            {deletingEvidenceId === index ? (
                                                <span className="whitespace-nowrap"><Trash className="w-4 h-4"/>?</span>
                                            ) : (
                                                <span className="whitespace-nowrap"><Trash className="w-4 h-4"/></span>
                                            )}
                                        </div>
                                        <div className="cursor-pointer" onClick={() => {
                                            setSelectedEvidence(evidence);
                                            setTimeout(() => {
                                                setIsSubModalVisible(true);
                                            }, 10);
                                        }}>
                                            <EvidenceDisplay evidence={evidence} index={index} />
                                        </div>
                                    </div>
                                );
                            })}
                        </div>
                    </div>
                    <div className="w-full flex flex-col gap-2">
                        <div className="w-full p-2 flex flex-row gap-2 items-center justify-center rounded-md bg-secondary/50 hover:bg-secondary/70 transition-all duration-300 cursor-pointer" onClick={() => {
                                const windowId = openWindow("file", file ? {
                                    ...file.document,
                                    content: documentContent,
                                    onDocumentSave: (content: string) => {
                                        setDocumentContent(content);
                                        fetchNui("updateFileDocument", {
                                            id: file?.id,
                                            content: content,
                                        });
                                    }
                                } : {
                                    ...defaultDocument,
                                    content: documentContent,
                                    onDocumentSave: (content: string) => {
                                        setDocumentContent(content);
                                    }
                                })
                                if (documentWindowId) {
                                    closeWindow(documentWindowId);
                                }
                                setTimeout(() => {
                                    setDocumentWindowId(windowId);
                                }, 10);
                            }}>
                            <EyeIcon className="w-4 h-4"/>
                            <div className="font-semibold text-sm"><Translate id="view_document" /></div>
                        </div>
                        {file ? (
                            <div className="w-full p-2 flex flex-row gap-2 items-center justify-center rounded-md bg-secondary/50 hover:bg-secondary/70 transition-all duration-300 cursor-pointer" onClick={() => {
                                fetchNui("printFile", {
                                    id: file.id,
                                });
                            }}>
                                <Printer className="w-4 h-4"/>
                                <div className="font-semibold text-sm"><Translate id="print_document" /></div>
                            </div>
                        ) : (
                            <div className="w-full p-2 flex flex-row gap-2 items-center justify-center rounded-md bg-green-600 hover:bg-green-700 transition-all duration-300 cursor-pointer" onClick={() => {
                                let createdFile = {
                                    name: fileName,
                                    authorIdentifier: fileAuthor,
                                    datetime: fileDate,
                                    evidence: fileEvidence,
                                    document: {
                                        ...defaultDocument,
                                        content: documentContent,
                                    },
                                }
                                fetchNui("createFile", createdFile);
                                closeModal();
                            }}>
                                <SaveIcon className="w-4 h-4"/>
                                <div className="font-semibold text-sm"><Translate id="save_document" /></div>
                            </div>
                        )}
                    </div>
                </div>
                {selectedEvidence && (
                    <SelectedEvidenceModal evidence={selectedEvidence} onClose={() => {
                        setIsSubModalVisible(false);
                        setTimeout(() => {
                            setSelectedEvidence(null);
                        }, 200);
                    }} isModalVisible={isSubModalVisible} />
                )}
                {isAddingEvidence && (
                    <AddEvidenceModal isCreatingFile={file ? false : true} importEvidence={(evidence: Evidence[]) => {
                        setFileEvidence(prev => [...prev, ...evidence]);
                        if (file) {
                            fetchNui("importEvidence", {
                                id: file.id,
                                evidence: evidence,
                            });
                        } 
                    }} onClose={() => {
                        setIsAddingEvidence(false);
                    }} isModalVisible={isSubModalVisible} />
                )}
            </div>
        </div>
    )
}

export default function FilesPage({ data }: { data?: any }) {
    const [files, setFiles] = useState<File[] | null>(null);
    const [selectedFile, setSelectedFile] = useState<File | null>(null);
    const [isAddingFile, setIsAddingFile] = useState(false);
    const [isModalVisible, setIsModalVisible] = useState(false);
    const [search, setSearch] = useState<string>("");
    useEffect(() => {
        setFiles(null);
        const debounceTimeout = setTimeout(() => {
            fetchNui("getFiles", {
                search: search,
            }).then((data: any) => {
                setFiles(data);
            });
        }, 500);

        return () => clearTimeout(debounceTimeout);
    }, [search]);
    useEffect(() => {
        const thread = async () => {
            fetchNui("getFiles", {
                search: search,
            }).then((data: any) => {
                setFiles(data);
            });
            // setTimeout(() => {
            //     setFiles(Array(10).fill(                    
            //         { name: "Test", authorIdentifier: "XLB21AB2", documentId: "1234", datetime: Date.now(), evidence: [
            //             {
            //                 "time": Date.now(),
            //                 "identifier": "XLB21AB2",
            //                 "coords": {
            //                     "x": -1291.5614013671876,
            //                     "y": -949.3941650390624,
            //                     "z": 10.29809379577636
            //                 },
            //                 "label": "Shell Casing",
            //                 "origin": {
            //                     "x": -1291.5614013671876,
            //                     "y": -949.3941650390624,
            //                     "z": 10.29809379577636
            //                 },
            //                 "heading": 40.8314208984375,
            //                 "type": "shell_casing",
            //                 "direction": {
            //                     "x": -1301.4219970703126,
            //                     "y": -937.9832153320313,
            //                     "z": 12.28249931335449
            //                 },
            //                 "weaponGroup": "GROUP_PISTOL",
            //                 "amount": 2,
            //                 "weaponHash": 453432689,
            //                 "image": "https://r2.fivemanage.com/2OthvhJFCzp3qiOWIvKTq/SYlVp4CtLde6.jpg"
            //             },
            //             {
            //                 "type": "blood",
            //                 "identifier": "XLB21AB2",
            //                 "label": "Blood",
            //                 "heading": 0.0,
            //                 "coords": {
            //                     "x": -1293.3231201171876,
            //                     "y": -949.8065795898438,
            //                     "z": 10.3179931640625
            //                 },
            //                 "image": "https://r2.fivemanage.com/2OthvhJFCzp3qiOWIvKTq/DevF71SPFLoZ.jpg"
            //             },
            //             {
            //                 "identifier": "XLB21AB2",
            //                 "coords": {
            //                     "x": -1293.3758544921876,
            //                     "y": -950.79736328125,
            //                     "z": 10.32188320159912
            //                 },
            //                 "label": "Shell Casing",
            //                 "origin": {
            //                     "x": -1293.3758544921876,
            //                     "y": -950.79736328125,
            //                     "z": 10.32188320159912
            //                 },
            //                 "heading": 31.2026138305664,
            //                 "type": "shell_casing",
            //                 "direction": {
            //                     "x": -1301.8514404296876,
            //                     "y": -936.803955078125,
            //                     "z": 12.56983947753906
            //                 },
            //                 "weaponGroup": "GROUP_PISTOL",
            //                 "amount": 2,
            //                 "weaponHash": 453432689,
            //                 "image": "https://r2.fivemanage.com/2OthvhJFCzp3qiOWIvKTq/HP4Xmx0ZfqeS.jpg"
            //             },
            //             {
            //                 "type": "blood",
            //                 "identifier": "XLB21AB2",
            //                 "label": "Blood",
            //                 "heading": 0.0,
            //                 "coords": {
            //                     "x": -1295.2747802734376,
            //                     "y": -948.949462890625,
            //                     "z": 10.3348388671875
            //                 },
            //                 "image": "https://r2.fivemanage.com/2OthvhJFCzp3qiOWIvKTq/bSsBpjIbSDgD.jpg"
            //             },
            //             {
            //                 "type": "blood",
            //                 "identifier": "XLB21AB2",
            //                 "label": "Blood",
            //                 "heading": 0.0,
            //                 "coords": {
            //                     "x": -1296.5802001953126,
            //                     "y": -947.2879028320313,
            //                     "z": 10.3348388671875
            //                 },
            //                 "image": "https://r2.fivemanage.com/2OthvhJFCzp3qiOWIvKTq/4JknhkmJwcK7.jpg"
            //             },
            //             {
            //                 "type": "fire",
            //                 "coords": {
            //                     "x": -1296.4620361328126,
            //                     "y": -942.640625,
            //                     "z": 10.336181640625
            //                 },
            //                 "label": "Fire / Explosive Residue",
            //                 "identifier": "XLB21AB2",
            //                 "heading": 0.0,
            //                 "explosionType": 3,
            //                 "image": "https://r2.fivemanage.com/2OthvhJFCzp3qiOWIvKTq/suLRfrgCO9FG.jpg"
            //             },
            //             {
            //                 "type": "blood",
            //                 "identifier": "XLB21AB2",
            //                 "label": "Blood",
            //                 "heading": 0.0,
            //                 "coords": {
            //                     "x": -1297.3978271484376,
            //                     "y": -943.002197265625,
            //                     "z": 10.3348388671875
            //                 },
            //                 "image": "https://r2.fivemanage.com/2OthvhJFCzp3qiOWIvKTq/AbeK9A32KpDU.jpg"
            //             },
            //             {
            //                 "type": "blood",
            //                 "identifier": "XLB21AB2",
            //                 "label": "Blood",
            //                 "heading": 0.0,
            //                 "coords": {
            //                     "x": -1297.186767578125,
            //                     "y": -945.098876953125,
            //                     "z": 10.3348388671875
            //                 },
            //                 "image": "https://r2.fivemanage.com/2OthvhJFCzp3qiOWIvKTq/QaAOn1sd7ChX.jpg"
            //             },
            //             {
            //                 "identifier": "XLB21AB2",
            //                 "coords": {
            //                     "x": -1290.0784912109376,
            //                     "y": -947.6670532226564,
            //                     "z": 10.24702453613281
            //                 },
            //                 "label": "Shell Casing",
            //                 "origin": {
            //                     "x": -1290.0784912109376,
            //                     "y": -947.6670532226564,
            //                     "z": 10.24702453613281
            //                 },
            //                 "heading": 65.09652709960938,
            //                 "type": "shell_casing",
            //                 "direction": {
            //                     "x": -1299.400634765625,
            //                     "y": -943.3391723632813,
            //                     "z": 11.05864715576171
            //                 },
            //                 "weaponGroup": "GROUP_PISTOL",
            //                 "amount": 2,
            //                 "weaponHash": 453432689,
            //                 "image": "https://r2.fivemanage.com/2OthvhJFCzp3qiOWIvKTq/c4eqgpsZTL8o.jpg"
            //             },
            //             {
            //                 "type": "vehicle",
            //                 "identifier": "XLB21AB2",
            //                 "coords": {
            //                     "x": -1289.5384521484376,
            //                     "y": -954.5010986328124,
            //                     "z": 10.8798828125
            //                 },
            //                 "label": "Vehicle",
            //                 "image": "https://r2.fivemanage.com/2OthvhJFCzp3qiOWIvKTq/ru2P6sRS4f0l.jpg",
            //                 "seats": {
            //                     "-1": {
            //                         "time": 1755925264,
            //                         "identifier": "XLB21AB2"
            //                     }
            //                 },
            //                 "plate": "ESX KISS",
            //                 "heading": 201.6681365966797
            //             }
            //         ]
            //     }));
            // }, 0);
        }
        thread();
    }, []);
    useNuiEvent("openFile", (data: any) => {
        if (!files?.find(file => file.id === data.file.id)) {
            setFiles(prev => [...(prev || []), data.file]);
        }
        setSelectedFile(data.file);
        setTimeout(() => {
            setIsModalVisible(true);
        }, 10);
    });
    useNuiEvent("updateFile", (data: any) => {
        setFiles(prev => prev?.map(file => file.id === data.file.id ? data.file : file) || []);
    });
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
            {isAddingFile && (
                <SelectedFileModal file={null} onClose={() => {
                    setIsAddingFile(false);
                }} isModalVisible={isModalVisible} />
            )}
            <div className="p-2">
                <div className="w-full flex flex-col gap-0 bg-secondary rounded-md p-1">
                    <input type="text" placeholder="Search" className="w-full h-[30px] bg-background/50 rounded-md p-2" value={search} onChange={(e) => {
                        setSearch(e.target.value);
                    }} />
                </div>
            </div>
            <div className="flex flex-row gap-2 justify-center items-center p-2 mb-2 ml-2 mr-2 cursor-pointer bg-secondary/50 rounded-md hover:bg-secondary/30 transition-all duration-300" onClick={() => {
                setIsAddingFile(true);
                setTimeout(() => {
                    setIsModalVisible(true);
                }, 10);
            }}>
                <FilePlusIcon className="w-4 h-4"/>
                <div className="font-semibold text-sm"><Translate id="add_file" /></div>
            </div>
            {files ? (
                <Table defaultSortKey="date" defaultSortDirection="desc" data={files.map(file => ({
                    ...file,
                    date: new Date(file.datetime * 1000).toLocaleString(),
                    action: (
                        <Button variant="outline" size="icon" onClick={() => handleFileSelect(file)}>
                            <EyeIcon className="w-4 h-4"/>
                        </Button>
                    ),
                }))} columns={[{
                    key: "name",
                    header: "Name",
                    sortable: true,
                }, {
                    key: "date",
                    header: "Date",
                    sortable: true,
                }, {
                    key: "action",
                    header: "",
                },]} sortFunction={(data, sortKey, sortDirection) => {
                    return data.sort((a, b) => {
                        let comparison = 0;
                        
                        if (sortKey === "date") {
                            comparison = a.datetime - b.datetime;
                        } else if (sortKey === "name") {
                            comparison = a.name.localeCompare(b.name);
                        }
                        
                        return sortDirection === 'desc' ? -comparison : comparison;
                    });
                }} />
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