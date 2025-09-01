import { useNuiEvent } from "@/providers/nui/useNui";
import { useEffect, useState } from "react";
import { Evidence, EvidenceDisplay, File, SelectedEvidenceModal } from "../computer/EvidencePage";
import { Eye, X } from "lucide-react";
import { fetchNui } from "@/providers/nui/fetchNui";
import DocumentContainer, { Document } from "../document/Document";
import { Translate } from "@/providers/locale/Locale";

export default function FileViewer() {
    const [visible, setVisible] = useState(false);
    const [isModalVisible, setIsModalVisible] = useState(false);
    const [selectedEvidence, setSelectedEvidence] = useState<Evidence | null>(null);
    const [reconstructSceneId, setReconstructSceneId] = useState<number | null>(null);
    const [file, setFile] = useState<File | null>( true ? null : { 
        id: 1,
        name: "Test", 
        authorIdentifier: "XLB21AB2",
        datetime: Date.now(), 
        document: {
            header: {
                title: "LOS SANTOS BALLS DEPARTMENT",
                image: "/nui/images/LSPD.webp",
                leftInfo: ["<b>Pickle Rick</b>", "1 Integrity Way"],
                rightInfo: ["<b>Chief of Police</b>", " L.S.P.D"],
            },
            subContent: [{ label: "Test" }],
            enableContent: true,
            content: ""
        },
        evidence: [
            {
                "time": Date.now(),
                "identifier": "XLB21AB2",
                "coords": {
                    "x": -1291.5614013671876,
                    "y": -949.3941650390624,
                    "z": 10.29809379577636
                },
                "label": "Shell Casing",
                "origin": {
                    "x": -1291.5614013671876,
                    "y": -949.3941650390624,
                    "z": 10.29809379577636
                },
                "heading": 40.8314208984375,
                "type": "shell_casing",
                "direction": {
                    "x": -1301.4219970703126,
                    "y": -937.9832153320313,
                    "z": 12.28249931335449
                },
                "weaponGroup": "GROUP_PISTOL",
                "amount": 2,
                "weaponHash": 453432689,
                "image": "/nui/images/bac.png"
            },
            {
                "type": "blood",
                "identifier": "XLB21AB2",
                "label": "Blood",
                "heading": 0.0,
                "coords": {
                    "x": -1293.3231201171876,
                    "y": -949.8065795898438,
                    "z": 10.3179931640625
                },
                "image": "https://r2.fivemanage.com/2OthvhJFCzp3qiOWIvKTq/DevF71SPFLoZ.jpg"
            },
            {
                "identifier": "XLB21AB2",
                "coords": {
                    "x": -1293.3758544921876,
                    "y": -950.79736328125,
                    "z": 10.32188320159912
                },
                "label": "Shell Casing",
                "origin": {
                    "x": -1293.3758544921876,
                    "y": -950.79736328125,
                    "z": 10.32188320159912
                },
                "heading": 31.2026138305664,
                "type": "shell_casing",
                "direction": {
                    "x": -1301.8514404296876,
                    "y": -936.803955078125,
                    "z": 12.56983947753906
                },
                "weaponGroup": "GROUP_PISTOL",
                "amount": 2,
                "weaponHash": 453432689,
                "image": "https://r2.fivemanage.com/2OthvhJFCzp3qiOWIvKTq/HP4Xmx0ZfqeS.jpg"
            },
            {
                "type": "blood",
                "identifier": "XLB21AB2",
                "label": "Blood",
                "heading": 0.0,
                "coords": {
                    "x": -1295.2747802734376,
                    "y": -948.949462890625,
                    "z": 10.3348388671875
                },
                "image": "https://r2.fivemanage.com/2OthvhJFCzp3qiOWIvKTq/bSsBpjIbSDgD.jpg"
            },
            {
                "type": "blood",
                "identifier": "XLB21AB2",
                "label": "Blood",
                "heading": 0.0,
                "coords": {
                    "x": -1296.5802001953126,
                    "y": -947.2879028320313,
                    "z": 10.3348388671875
                },
                "image": "https://r2.fivemanage.com/2OthvhJFCzp3qiOWIvKTq/4JknhkmJwcK7.jpg"
            },
            {
                "type": "fire",
                "coords": {
                    "x": -1296.4620361328126,
                    "y": -942.640625,
                    "z": 10.336181640625
                },
                "label": "Fire / Explosive Residue",
                "identifier": "XLB21AB2",
                "heading": 0.0,
                "explosionType": 3,
                "image": "https://r2.fivemanage.com/2OthvhJFCzp3qiOWIvKTq/suLRfrgCO9FG.jpg"
            },
            {
                "type": "blood",
                "identifier": "XLB21AB2",
                "label": "Blood",
                "heading": 0.0,
                "coords": {
                    "x": -1297.3978271484376,
                    "y": -943.002197265625,
                    "z": 10.3348388671875
                },
                "image": "https://r2.fivemanage.com/2OthvhJFCzp3qiOWIvKTq/AbeK9A32KpDU.jpg"
            },
            {
                "type": "blood",
                "identifier": "XLB21AB2",
                "label": "Blood",
                "heading": 0.0,
                "coords": {
                    "x": -1297.186767578125,
                    "y": -945.098876953125,
                    "z": 10.3348388671875
                },
                "image": "https://r2.fivemanage.com/2OthvhJFCzp3qiOWIvKTq/QaAOn1sd7ChX.jpg"
            },
            {
                "identifier": "XLB21AB2",
                "coords": {
                    "x": -1290.0784912109376,
                    "y": -947.6670532226564,
                    "z": 10.24702453613281
                },
                "label": "Shell Casing",
                "origin": {
                    "x": -1290.0784912109376,
                    "y": -947.6670532226564,
                    "z": 10.24702453613281
                },
                "heading": 65.09652709960938,
                "type": "shell_casing",
                "direction": {
                    "x": -1299.400634765625,
                    "y": -943.3391723632813,
                    "z": 11.05864715576171
                },
                "weaponGroup": "GROUP_PISTOL",
                "amount": 2,
                "weaponHash": 453432689,
                "image": "https://r2.fivemanage.com/2OthvhJFCzp3qiOWIvKTq/c4eqgpsZTL8o.jpg"
            },
            {
                "type": "vehicle",
                "identifier": "XLB21AB2",
                "coords": {
                    "x": -1289.5384521484376,
                    "y": -954.5010986328124,
                    "z": 10.8798828125
                },
                "label": "Vehicle",
                "image": "https://r2.fivemanage.com/2OthvhJFCzp3qiOWIvKTq/ru2P6sRS4f0l.jpg",
                "seats": {
                    "-1": {
                        "time": 1755925264,
                        "identifier": "XLB21AB2"
                    }
                },
                "plate": "ESX KISS",
                "heading": 201.6681365966797
            }
        ]
    });
    useEffect(() => {
        const handleKeyDown = (event: KeyboardEvent) => {
            if (event.target instanceof HTMLInputElement || event.target instanceof HTMLTextAreaElement) return;
            if (!visible) return;
            if (event.key === "Escape") {
                fetchNui("closeFileViewer", {});
            }
        };

        window.addEventListener("keydown", handleKeyDown);

        return () => {
            window.removeEventListener("keydown", handleKeyDown);
        };
    });
    const toggleFileViewer = (data?: File) => {
        if (data) {
            setFile(data);
            setTimeout(() => {
                setVisible(true);
            }, 10);
        } else {
            setVisible(false);
            setTimeout(() => {
                setFile(null);
                setIsModalVisible(false);
                setSelectedEvidence(null);
            }, 300);
        }
    }
    useNuiEvent("setFileViewer", (data: any) => {
        toggleFileViewer(data.file);
        setReconstructSceneId(data.reconstructSceneId);
    });
    return file &&(
        <div className="w-screen h-screen absolute top-0 left-0 flex items-center justify-center text-white">
            <div className={`dark bg-background/95 w-[${file.evidence.length > 0 ? '800px' : '600px'}] relative shadow-lg transition-all duration-200 ${visible ? 'scale-100 opacity-100' : 'scale-95 opacity-0'}`}>
            {selectedEvidence && (
                    <SelectedEvidenceModal evidence={selectedEvidence} onClose={() => {
                        setIsModalVisible(false);
                        setTimeout(() => {
                            setSelectedEvidence(null);
                        }, 200);
                    }} isModalVisible={isModalVisible} />
                )}
                <div className="relative w-full h-[30px] bg-secondary flex items-center justify-between select-none ">
                    <div className="flex items-center justify-center gap-2 pl-2">
                        <div className="font-semibold text-sm text-white">{file.name}</div>
                    </div>
                    <div className="flex items-center justify-center gap-2 hover:bg-destructive/50 transition-all duration-300 h-[30px] w-[30px] cursor-pointer" onClick={() => {
                        fetchNui("closeFileViewer");
                    }}>
                        <X/>
                    </div>
                </div>
                <div className="w-full flex flex-col p-2 gap-2 relative justify-between h-[calc(100%-30px)]">
                    {file.evidence.length > 0 && (
                        reconstructSceneId != null ? (
                            <div className="w-full h-[30px] bg-secondary hover:bg-secondary/80 transition-all duration-300 cursor-pointer rounded-md flex items-center justify-center gap-2 select-none" onClick={() => {
                                fetchNui("reconstructScene", {});
                                setReconstructSceneId(null);
                            }}>
                                <Eye className="w-4 h-4" />
                                <div className="font-semibold text-sm text-white"><Translate id="stop_reconstruct_scene" /></div>
                            </div>
                        ) : (
                            <div className="w-full h-[30px] bg-secondary hover:bg-secondary/80 transition-all duration-300 cursor-pointer rounded-md flex items-center justify-center gap-2 select-none" onClick={() => {
                                fetchNui("reconstructScene", {
                                    file: file,
                                });
                                fetchNui("closeFileViewer", {});
                            }}>
                                <Eye className="w-4 h-4" />
                                <div className="font-semibold text-sm text-white"><Translate id="reconstruct_scene" /></div>
                            </div>
                        )   
                    )}
                    <div className="flex flex-row gap-2">
                        <div className="w-[600px] h-[774px]">
                            <Document canEdit={false} dark={true} width={file.evidence.length > 0 ? 600 : 584} height={774} initialContent={file.document.content} headerInfo={file.document.header} />
                        </div>
                        {file.evidence.length > 0 && (
                            <div className="w-[200px] h-[774px] flex flex-col gap-2 overflow-y-auto cursor-pointer">
                                {file.evidence.map((evidence, index) => (
                                    <div onClick={() => {
                                        setSelectedEvidence(evidence);
                                        setTimeout(() => {
                                            setIsModalVisible(true);
                                        }, 10);
                                    }}>
                                        <EvidenceDisplay evidence={evidence} index={index} />
                                    </div>
                                ))}
                            </div>
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
}