import { AppControls } from "@/App";
import { Translate, translateText } from "@/providers/locale/Locale";
import { useNuiEvent } from "@/providers/nui/useNui";
import { Maximize, Maximize2, Minus, MinusIcon, PictureInPicture, PictureInPicture2, X } from "lucide-react";
import { useContext, useEffect, useState, useRef } from "react";
import RosterPage, { DepartmentMember } from "./RosterPage";
import FinancePage from "./FinancePage";
import { createContext } from "react";
import { useConfig } from "@/providers/config";
import DocumentContainer, { Document, DocumentDisplay } from "../document/Document";
import { Location } from "../management/Management";
import { fetchNui } from "@/providers/nui/fetchNui";
import FilesPage from "./EvidencePage";

export type Rank = {
    rankId: number;
    jobLevel: number;
    label: string;
    salary: number;
    managingRankIds: number[];
    armory: string[];
    vehicles: number[];
}

export type DepartmentPermission = {
    managingRankIds: number[];
    armory: string[];
    vehicles: number[];
}

export type DepartmentTransactions = {
    id: number;
    identifier: string;
    name: string;
    amount: number;
    reason: string;
    type: "withdraw" | "deposit";
    time: number;
}

export type Department = {
    id: number;
    location: Location;
    money: number;
    job: string;
    label: string;
    image: string;
    ranks: Rank[];
    permissions: Record<string, DepartmentPermission>;
    members: DepartmentMember[];
    locations: DepartmentLocation[];
    misc: {
        transactions: DepartmentTransactions[];
        showBlip?: boolean;
    }
}

export type DepartmentLocation = {
    id: number,
    type: string,
    settings: Record<string, any>,
    positions: Record<string, Location>,
}

type ComputerInfo = {
    department: Department;
    backgroundImage: string;
}

type ComputerWindow = {
    programId: string;
    id: number;
    name: string;
    image: string;
    visible: boolean;
    x?: number;
    y?: number;
    data?: any;
}

interface ComputerContextProps {
    computerInfo: ComputerInfo;
    player: DepartmentMember;
    windows: ComputerWindow[];
    department: Department;
    setDepartment: (department: Department) => void;
    openWindow: (window: string, data?: any) => number;
    closeWindow: (id: number) => void;
}

const ComputerContext = createContext<ComputerContextProps | undefined>(undefined);

function Computer({info}: {info: ComputerInfo}) {
    const [computerInfo, setComputerInfo] = useState<ComputerInfo>(info);
    const {config} = useConfig();
    const [windows, setWindows] = useState<ComputerWindow[]>([]);
    const [currentWindow, setCurrentWindow] = useState<ComputerWindow | null>(null);
    const [isDragging, setIsDragging] = useState(false);
    const [dragOffset, setDragOffset] = useState({ x: 0, y: 0 });
    const [department, setDepartment] = useState<Department>(info.department);
    const player = department.members.find((member) => member.identifier === config.identifier) || {
        identifier: "ERR_CLOSE",
        rankId: 1,
        name: "Unknown",
        recentDutyLogs: [],
        permissions: {},
        onDutyTime: 0,
    }
    const rankIndex = department.ranks.findIndex(rank => rank.rankId === player.rankId);
    if (player.identifier === "ERR_CLOSE") {
        fetchNui("closeComputer");
    }
    
    useNuiEvent("updateComputerDepartment", (event: any) => {
        const data = event.data;
        if (data.type == "updateMembers") {
            setDepartment(prev => ({
                ...prev,
                members: data.members,
            }));
        } else if (data.type == "updateRanks") {
            setDepartment(prev => ({
                ...prev,
                ranks: data.ranks,
            }));
        } else if (data.type == "updatePermissions") {
            setDepartment(prev => ({
                ...prev,
                permissions: data.permissions,
            }));
        } else if (data.type == "updateFinance") {
            setDepartment(prev => ({
                ...prev,
                money: data.money,
            }));
        } else if (data.type == "updateTransactions") {
            setDepartment(prev => ({
                ...prev,
                misc: {
                    ...prev.misc,
                    transactions: data.transactions,
                },
            }));
        }
    });
    // Mouse event handlers for dragging
    const handleMouseDown = (e: React.MouseEvent, window: ComputerWindow) => {
        e.preventDefault();     
        setIsDragging(true);
        setCurrentWindow(window);
        
        const rect = e.currentTarget.getBoundingClientRect();
        const offsetX = e.clientX - rect.left;
        const offsetY = e.clientY - rect.top;
        setDragOffset({ x: offsetX, y: offsetY });
    };

    const handleMouseMove = (e: MouseEvent) => {
        if (!isDragging || !currentWindow) return;

        const container = document.querySelector('.relative.w-full.h-\\[calc\\(100\\%-40px\\)\\]') as HTMLElement;
        if (!container) return;

        const containerRect = container.getBoundingClientRect();
        
        // Get the actual window element to determine its dimensions
        const windowElement = document.querySelector(`[data-window-id="${currentWindow.id}"]`) as HTMLElement;
        if (!windowElement) return;
        
        const windowRect = windowElement.getBoundingClientRect();
        const windowWidth = windowRect.width;
        const windowHeight = windowRect.height;

        let newX = e.clientX - containerRect.left - dragOffset.x;
        let newY = e.clientY - containerRect.top - dragOffset.y;

        // Constrain to container bounds
        newX = Math.max(0, Math.min(newX, containerRect.width - windowWidth));
        newY = Math.max(0, Math.min(newY, containerRect.height - windowHeight));

        setWindows(prev => prev.map(window => 
            window.id === currentWindow.id 
                ? { ...window, x: newX, y: newY }
                : window
        ));
    };

    const handleMouseUp = () => {
        setIsDragging(false);
        setDragOffset({ x: 0, y: 0 });
    };

    useEffect(() => {
        if (isDragging) {
            document.addEventListener('mousemove', handleMouseMove);
            document.addEventListener('mouseup', handleMouseUp);
            
            return () => {
                document.removeEventListener('mousemove', handleMouseMove);
                document.removeEventListener('mouseup', handleMouseUp);
            };
        }
    }, [isDragging, currentWindow, dragOffset]);

    const handleShortcutSelect = (program: typeof programs[number], data?: any): number => {
        if (program.id === "bail") {
            fetchNui("openBailBounty");
            return -1;
        }
        function generateUniqueId() {
            let id = Math.floor(Math.random() * 1000000);
            let exists = false;
            for (const window of windows) {
                if (window.id === id) {
                    exists = true;
                    break;
                }
            }
            if (exists) {
                return generateUniqueId();
            }
            return id;
        }
        let x: number | undefined;
        let y: number | undefined;
        if (windows.length > 0) {
            const container = document.querySelector('.relative.w-full.h-\\[calc\\(100\\%-40px\\)\\]') as HTMLElement;
            if (!container) return -1;
            const containerRect = container.getBoundingClientRect();
            const windowWidth = containerRect.width * 0.75; // 75% of container width
            const windowHeight = containerRect.height * 0.75; // 75% of container height
            x = Math.random() * (containerRect.width - windowWidth);
            y = Math.random() * (containerRect.height - windowHeight);
        }
        const id = generateUniqueId();
        const window = {
            id: id,
            name: program.name,
            image: program.image,
            programId: program.id,
            visible: false,
            x: x,
            y: y,
            data: data
        }
        setWindows(prev => [...prev, window]);
        setCurrentWindow(window);
        setTimeout(() => {
            setWindows(prev => prev.map(window => 
                window.id === id ? { ...window, visible: true } : window
            ));
        }, 10);
        return id;
    };

    const handleProgramDeselect = (id: number) => {
        setWindows(prev => prev.map(window => 
            window.id === id ? { ...window, visible: false } : window
        ));
        if (currentWindow?.id === id) {
            setCurrentWindow(null);
        }
        setTimeout(() => {
            setWindows(prev => prev.filter(window => window.id !== id));
        }, 100);
    };

    const programs = [
        {
            id: "roster",
            name: "page_roster",
            image: department.image
        },
        {
            id: "files",
            name: "page_files",
            image: "/nui/images/files_icon.png",
            hideShortcut: !config.evidenceEnabled,
        },
        {
            id: "file",
            name: "page_file",
            image: "/nui/images/files_icon.png",
            hideShortcut: true,
        },
        {
            id: "finance",
            name: "page_finance",
            image: "/nui/images/finance_icon.png",
            hideShortcut: rankIndex !== 0,
        },
        {
            id: "bail",
            name: "page_bail",
            image: "/nui/images/bail_icon.png",
            hideShortcut: !config.bailAndBounty,
        },
    ]
    const [currentDateTime, setCurrentDateTime] = useState<Date>(new Date());
    // useEffect(() => {
    //     const interval = setInterval(() => {
    //         setCurrentDateTime(new Date());
    //     }, 1000);
    //     return () => clearInterval(interval);
    // }, []);
    return (
        <ComputerContext.Provider value={{
            computerInfo,
            department,
            player: player as DepartmentMember,
            windows,
            setDepartment,
            openWindow: (window: string, data?: any): number => {
                return handleShortcutSelect(programs.find(program => program.id === window)!, data);
            },
            closeWindow: (id: number) => {
                handleProgramDeselect(id);
            }
        }}>
            <div className="relative w-[1280px] h-[720px] flex flex-col items-center justify-center overflow-hidden" style={{
                backgroundImage: `url(${computerInfo.backgroundImage})`,
                backgroundSize: "cover",
                backgroundPosition: "center",
                backgroundRepeat: "no-repeat",
            }}>
                <div className="relative w-full h-[calc(100%-40px)]">
                    {windows.map((window, index) => (
                        <div 
                            key={window.id}
                            data-window-id={window.id}
                            className={`absolute bg-background transition-opacity duration-100 window-container`} 
                            style={{
                                width: window.programId === "file" ? "unset" : "75%",
                                height: window.programId === "file" ? "unset" : "75%",
                                pointerEvents: window.visible ? 'auto' : 'none',
                                opacity: window.visible ? 1 : 0,
                                zIndex: currentWindow?.id === window.id ? 100 : 10,
                                top: window.y !== undefined ? `${window.y}px` : '50%',
                                left: window.x !== undefined ? `${window.x}px` : '50%',
                                transform: window.x === undefined && window.y === undefined ? 'translate(-50%, -50%)' : 'none',
                                boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.8), 0 0 0 1px rgba(255, 255, 255, 0.1)',
                            }}
                            onMouseDown={() => setCurrentWindow(window)}
                        >
                            <div 
                                className="relative w-full h-[30px] bg-secondary flex items-center justify-between select-none"
                                onMouseDown={(e) => handleMouseDown(e, window)}
                            >
                                <div className="flex items-center justify-center gap-2 pl-2">
                                    <img src={window.image} alt={""} className="w-[15px] h-[15px]" />
                                    <div className="font-semibold text-sm text-white">{<Translate id={window.name} />}</div>
                                </div>
                                <div className="flex items-center gap-0">
                                    <div className="flex items-center justify-center gap-2 hover:bg-primary/50 transition-all duration-300 h-[30px] w-[30px] cursor-pointer" onClick={() => {
                                        setWindows(prev => prev.map(targetWindow => 
                                            window.id === targetWindow.id ? { ...targetWindow, visible: false } : targetWindow
                                        ));
                                        if (currentWindow?.id === window.id) {
                                            setCurrentWindow(null);
                                        }
                                    }}>
                                        <Minus/>
                                    </div>
                                    <div className="flex items-center justify-center gap-2 hover:bg-red-500 transition-all duration-300 h-[30px] w-[30px] cursor-pointer" onClick={() => handleProgramDeselect(window.id)}>
                                        <X/>
                                    </div>
                                </div>
                            </div>
                            <div className="w-full h-[calc(100%-30px)] relative">
                                {window.programId === "roster" && <RosterPage />}
                                {window.programId === "files" && <FilesPage data={window.data} />}
                                {window.programId === "finance" && <FinancePage />}
                                {window.programId === "file" && <DocumentDisplay
                                    documentInfo={window.data}
                                    dark={true} 
                                    width={600 * 0.8} 
                                    height={774 * 0.8} 
                                    canEdit={window.data.canEdit === undefined ? true : window.data.canEdit} 
                                />}
                            </div>
                        </div>
                    ))}
                    <div className="absolute top-0 left-0 flex flex-col gap-2 p-4 select-none">
                        {programs.filter(program => !program.hideShortcut).map((program, index) => (
                            <div className="flex flex-col items-center justify-center gap-1 hover:bg-background/25 rounded-sm py-2 px-1 cursor-pointer" key={index} onClick={() => handleShortcutSelect(program)}>
                                <img src={program.image} alt={"program.name"} className="w-[50px] h-[50px]" draggable={false} />
                                <div className="font-bold text-sm text-white">{<Translate id={program.name} />}</div>
                            </div>
                        ))}
                    </div>
    
                </div>
                <div className="relative w-full h-[40px] bg-black/50 flex items-center justify-between px-2">
                    <div className="flex items-center gap-2 whitespace-nowrap">
                        <img src={department.image} alt="home" className="w-[25px] h-[25px]" />
                        <div className="text-sm font-semibold text-white">{config.name}</div>
                        <div className="flex overflow-x-auto gap-0">
                            {windows.map((window, index) => (
                                <div 
                                    key={index} 
                                    className="flex items-center justify-center w-[40px] h-[40px] relative group hover:bg-white/50 cursor-pointer"
                                    title={translateText(config, window.name, [])}
                                    onClick={() => {
                                        setCurrentWindow(window);
                                        setWindows(prev => prev.map(targetWindow => 
                                            window.id === targetWindow.id ? { ...targetWindow, visible: true } : targetWindow
                                        ));
                                    }}
                                >
                                    <div className="w-[25px] h-[25px] z-10" style={{
                                        backgroundImage: `url(${window.image})`,
                                        backgroundSize: "cover",
                                        backgroundPosition: "center",
                                        backgroundRepeat: "no-repeat",
                                    }}></div>
                                    {currentWindow?.id === window.id && <div className="absolute top-0 left-0 w-full h-full bg-black/50"></div>}
                                </div>
                            ))}
                        </div>
                    </div>
                    <div className="flex flex-col items-end justify-center">
                        <div className="text-xs text-white">{currentDateTime.toLocaleTimeString([], {hour: '2-digit', minute: '2-digit'})}</div>
                        <div className="text-xs text-white">{currentDateTime.toLocaleDateString()}</div>
                    </div>
                </div>
            </div>
        </ComputerContext.Provider>
    )
}

export const useComputer = (): ComputerContextProps => {
    const context = useContext(ComputerContext);
    if (!context) {
        throw new Error('useComputer must be used within a ComputerProvider');
    }
    return context;
}

export default function ComputerContainer() {
    const [visible, setVisible] = useState(false);
    const [computerInfo, setComputerInfo] = useState<ComputerInfo | null>(true ? null : {
        department: {
            location: {
                coords: {
                    x: 0,
                    y: 0,
                    z: 0,
                },
                rotation: {
                    x: 0,
                    y: 0,
                    z: 0,
                },
            },
            id: 11,
            image: "nui/images/app_icon.png",
            money: 1000000,
            label: "Los Santos Police Department",
            job: "police",
            misc: {
                transactions: Array.from({length: 20}, (_, i) => ({
                    id: i,
                    identifier: "char1:eeee",
                    name: "Michael Rodriguez (" + (i+1) + ")",
                    amount: 1000000 + (i * 25000),
                    reason: "Salary",
                    type: i % 3 === 0 ? "withdraw" : "deposit",
                    time: (Date.now() - (i * 1000)) / 1000,
                })),
            },
            ranks: [
                {
                    "rankId":1,
                    "jobLevel": 4,
                    "label":"Chief", 
                    "managingRankIds":[],
                    "armory": [],
                    "vehicles": [],
                    "salary": 1000000,
                },
                {
                    "rankId":2,
                    "jobLevel": 3,
                    "label":"Lieutenant", 
                    "managingRankIds":[],
                    "armory": [],
                    "vehicles": [],
                    "salary": 1000000,
                },
                {
                    "rankId":3,
                    "jobLevel": 3,
                    "label":"Sergeant",
                    "managingRankIds":[2],
                    "armory": [],
                    "vehicles": [],
                    "salary": 1000000,
                },
                {
                    "rankId":4,
                    "jobLevel": 1,
                    "label":"Officer",
                    "managingRankIds":[1,2,3],
                    "armory": [],
                    "vehicles": [],
                    "salary": 1000000,
                },
                {
                    "rankId":5,
                    "jobLevel": 0,
                    "label":"Recruit",
                    "managingRankIds":[1,2,3],
                    "armory": [],
                    "vehicles": [],
                    "salary": 1000000,
                },
            ],
            members: [
                {
                    "identifier": "char1:eeee",
                    "name": "Michael Rodriguez",
                    "rankId": 4,
                    "recentDutyLogs": [],
                    "permissions": ["Rifle Certified", "Field Training Officer"],
                    "onDutyTime": 22,
                },
                {
                    "identifier": "char1:7817bde6206cb72577821aa3369e8d15f688138b",
                    "name": "Sarah Johnson",
                    "rankId": 2,
                    "recentDutyLogs": [],
                    "permissions": ["Rifle Certified", "Air Certified", "Field Training Officer"],
                    "onDutyTime": 256,
                },
                {
                    "identifier": "char1:eeee2",
                    "name": "David Chen",
                    "rankId": 4,
                    "recentDutyLogs": [],
                    "permissions": [],
                    "onDutyTime": 12020,
                },
                {
                    "identifier": "char1:7817bde6206cb72577821aa3369e8d15f688138c",
                    "name": "Emily Thompson",
                    "rankId": 2,
                    "recentDutyLogs": [],
                    "permissions": [],
                    "onDutyTime": 42001,
                },
                {
                    "identifier": "char1:eeee3",
                    "name": "James Wilson",
                    "rankId": 4,
                    "recentDutyLogs": [],
                    "permissions": [],
                    "onDutyTime": 2233,
                },
                {
                    "identifier": "char1:7817bde6206cb72577821aa3369e8d15f688138d",
                    "name": "Lisa Martinez",
                    "rankId": 2,
                    "recentDutyLogs": [],
                    "permissions": [],
                    "onDutyTime": 54321,
                },
                {
                    "identifier": "char1:eeee4",
                    "name": "Robert Kim",
                    "rankId": 4,
                    "recentDutyLogs": [],
                    "permissions": [],
                    "onDutyTime": 2222,
                },
                {
                    "identifier": "char1:7817bde6206cb72577821aa3369e8d15f688138e",
                    "name": "Jennifer Davis",
                    "rankId": 2,
                    "recentDutyLogs": [],
                    "permissions": [],
                    "onDutyTime": 1123,
                },
                {
                    "identifier": "char1:eeee5",
                    "name": "Christopher Lee",
                    "rankId": 4,
                    "recentDutyLogs": [],
                    "permissions": [],
                    "onDutyTime": 52431,
                },
                {
                    "identifier": "char1:7817bde6206cb72577821aa3369e8d15f688138f",
                    "name": "Amanda Garcia",
                    "rankId": 2,
                    "recentDutyLogs": [
                        {
                            "duration": 8,
                            "finishTimestamp": "06\/19\/2025 05:04 PM",
                            "startTimestamp": "06\/19\/2025 05:04 PM",
                            "finish": 1760374288
                        },
                    ],
                    "permissions": [],
                    "onDutyTime": 2442,
                },
                {
                    "identifier": "char1:7817bde6206cb72577821aa3369e8d15f688138a",
                    "name": "Marcus Williams",
                    "rankId": 1,
                    "recentDutyLogs": [
                        {
                            "duration": 8,
                            "report": "a",
                            "finishTimestamp": "06\/19\/2025 05:04 PM",
                            "startTimestamp": "06\/19\/2025 05:04 PM",
                            "finish": 1750374288
                        },
                        {
                            "duration": 18,
                            "finishTimestamp": "06\/18\/2025 02:20 PM",
                            "startTimestamp": "06\/18\/2025 02:20 PM",
                            "finish": 1750278018
                        },
                        {
                            "duration": 7,
                            "finishTimestamp": "06\/18\/2025 07:25 AM",
                            "startTimestamp": "06\/18\/2025 07:25 AM",
                            "finish": 1750253124
                        },
                        {
                            "duration": 23,
                            "startTimestamp": "06\/17\/2025 11:59 AM",
                            "finishTimestamp": "06\/17\/2025 11:59 AM",
                            "finish": 1750183198
                        },
                        {
                            "duration": 7,
                            "startTimestamp": "06\/17\/2025 11:41 AM",
                            "report": "Aaaaaa",
                            "finishTimestamp": "06\/17\/2025 11:41 AM",
                            "finish": 1750182092
                        },
                        {
                            "duration": 16,
                            "startTimestamp": "06\/17\/2025 11:20 AM",
                            "report": "I am tired\n",
                            "finishTimestamp": "06\/17\/2025 11:20 AM",
                            "finish": 1750180829
                        },
                        {
                            "duration": 6,
                            "finishTimestamp": "06\/17\/2025 04:29 AM",
                            "startTimestamp": "06\/17\/2025 04:29 AM",
                            "finish": 1750156199
                        },
                        {
                            "duration": 72441,
                            "finishTimestamp": "06\/16\/2025 08:01 AM",
                            "startTimestamp": "06\/15\/2025 11:53 AM",
                            "finish": 1750082474
                        },
                        {
                            "duration": 7,
                            "finishTimestamp": "06\/15\/2025 08:04 AM",
                            "startTimestamp": "06\/15\/2025 08:04 AM",
                            "finish": 1749996260
                        },
                        {
                            "duration": 260,
                            "finishTimestamp": "06\/15\/2025 08:03 AM",
                            "startTimestamp": "06\/15\/2025 07:58 AM",
                            "finish": 1749996181
                        }
                    ],
                    "permissions": [
                    ],
                    "onDutyTime": 72932,
                },
            ],
            permissions: {
                "Air Certified": {
                    "managingRankIds": [2],
                    "armory": [],
                    "vehicles": [],
                },
                "Field Training Officer": {
                    "managingRankIds": [2, 3],
                    "armory": [],
                    "vehicles": [],
                },
                "Rifle Certified": {
                    "managingRankIds": [2, 3],
                    "armory": [],
                    "vehicles": [],
                },
            },
            locations: [],
        },
        backgroundImage: "nui/images/computer_background.png",
    });
    useEffect(() => {
        const handleKeyDown = (event: KeyboardEvent) => {
            if (event.target instanceof HTMLInputElement || event.target instanceof HTMLTextAreaElement) return;
            if (!visible) return;
            if (event.key === "Escape") {
                fetchNui("closeComputer", {});
            }
        };

        window.addEventListener("keydown", handleKeyDown);

        return () => {
            window.removeEventListener("keydown", handleKeyDown);
        };
    });
    const updateComputerInfo = (data: any) => {
        if (!data.computerInfo) {
            setVisible(false);
            setTimeout(() => {
                setComputerInfo(data.computerInfo);
            }, 300);
        }
        else {
            setComputerInfo(data.computerInfo);
            setTimeout(() => {
                setVisible(true);
            }, 10);
        }
    }
    useNuiEvent("updateComputerInfo", updateComputerInfo);
    useNuiEvent("setComputerVisible", (data: any) => {
        setVisible(data.visible);
    });
    return (
        computerInfo && (
            <div className="dark w-screen h-screen absolute text-primary top-0 left-0 flex items-center justify-center transition-opacity duration-300" style={{opacity: visible ? 1 : 0}}>
                <AppControls />
                <Computer info={computerInfo} />
            </div>
        )
    )
}