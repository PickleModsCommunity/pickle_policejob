import { AppControls } from "@/App";
import { Translate, translateText } from "@/providers/locale/Locale";
import { useNuiEvent } from "@/providers/nui/useNui";
import { usePlayer } from "@/providers/player/player";
import { MinusIcon, X } from "lucide-react";
import { useContext, useEffect, useState, useRef } from "react";
import HomePage from "./HomePage";
import RosterPage from "./RosterPage";
import EvidencePage from "./EvidencePage";
import SettingsPage from "./SettingsPage";
import { createContext } from "react";
import { useConfig } from "@/providers/config";

type ComputerInfo = {
    backgroundImage: string;
    homeImage: string;
}

type ComputerWindow = {
    programId: string;
    id: number;
    name: string;
    image: string;
    visible: boolean;
    x?: number;
    y?: number;
}

interface ComputerContextProps {
    computerInfo: ComputerInfo;
    windows: ComputerWindow[];
}

const ComputerContext = createContext<ComputerContextProps | undefined>(undefined);

function Computer({info}: {info: ComputerInfo}) {
    const [computerInfo, setComputerInfo] = useState<ComputerInfo>(info);
    const {config} = useConfig();
    const {player} = usePlayer();
    const [windows, setWindows] = useState<ComputerWindow[]>([]);
    const [currentWindow, setCurrentWindow] = useState<ComputerWindow | null>(null);
    const [isDragging, setIsDragging] = useState(false);
    const [dragOffset, setDragOffset] = useState({ x: 0, y: 0 });

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
        const windowWidth = containerRect.width * 0.75; // 75% of container width
        const windowHeight = containerRect.height * 0.75; // 75% of container height

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

    const handleShortcutSelect = (program: typeof programs[number]) => {
        function generateUniqueId() {
            let id = 1;
            for (const window of windows) {
                if (window.id === id) {
                    id = window.id + 1;
                }
            }
            return id;
        }
        let x: number | undefined;
        let y: number | undefined;
        if (windows.length > 0) {
            const container = document.querySelector('.relative.w-full.h-\\[calc\\(100\\%-40px\\)\\]') as HTMLElement;
            if (!container) return;
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
            y: y
        }
        setWindows(prev => [...prev, window]);
        setCurrentWindow(window);
        setTimeout(() => {
            setWindows(prev => prev.map(window => 
                window.id === id ? { ...window, visible: true } : window
            ));
        }, 10);
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
            id: "homepage",
            name: "page_homepage",
            image: "nui/images/LSPD.webp"
        },
        {
            id: "roster",
            name: "page_roster",
            image: "nui/images/LSPD.webp"
        },
        {
            id: "evidence",
            name: "page_evidence",
            image: "nui/images/LSPD.webp"
        },
        {
            id: "settings",
            name: "page_settings",
            image: "nui/images/LSPD.webp"
        },
    ]
    const [currentDateTime, setCurrentDateTime] = useState<Date>(new Date());
    useEffect(() => {
        const interval = setInterval(() => {
            setCurrentDateTime(new Date());
        }, 1000);
        return () => clearInterval(interval);
    }, []);
    const value = {
        computerInfo,
        windows
    }
    return (
        <ComputerContext.Provider value={value}>
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
                            className={`absolute w-[75%] h-[75%] bg-background transition-opacity duration-100 window-container ${window.visible ? 'opacity-100' : 'opacity-0'}`} 
                            style={{
                                zIndex: currentWindow?.id === window.id ? 100 : 10,
                                top: window.y !== undefined ? `${window.y}px` : '50%',
                                left: window.x !== undefined ? `${window.x}px` : '50%',
                                transform: window.x === undefined && window.y === undefined ? 'translate(-50%, -50%)' : 'none',
                                cursor: isDragging && currentWindow?.id === window.id ? 'grabbing' : 'default',
                                boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.8), 0 0 0 1px rgba(255, 255, 255, 0.1)',
                            }}
                            onMouseDown={() => setCurrentWindow(window)}
                        >
                            <div 
                                className="relative w-full h-[30px] bg-secondary flex items-center justify-between select-none cursor-grab active:cursor-grabbing"
                                onMouseDown={(e) => handleMouseDown(e, window)}
                            >
                                <div className="flex items-center justify-center gap-2 pl-2">
                                    <img src={window.image} alt={""} className="w-[15px] h-[15px]" />
                                    <div className="font-semibold text-sm text-white">{<Translate id={window.name} />}</div>
                                </div>
                                <div className="flex items-center justify-center gap-2 hover:bg-red-500 transition-all duration-300 h-[30px] w-[30px] cursor-pointer" onClick={() => handleProgramDeselect(window.id)}>
                                    <X/>
                                </div>
                            </div>
                            <div className="w-full h-[calc(100%-30px)]">
                                {window.programId === "homepage" && <HomePage />}
                                {window.programId === "roster" && <RosterPage />}
                                {window.programId === "evidence" && <EvidencePage />}
                                {window.programId === "settings" && <SettingsPage />}
                            </div>
                        </div>
                    ))}
                    <div className="absolute top-0 left-0 flex flex-col gap-2 p-4 select-none">
                        {programs.map((program, index) => (
                            <div className="flex flex-col items-center justify-center gap-1 hover:bg-background/25 rounded-sm py-2 px-1 cursor-pointer" key={index} onClick={() => handleShortcutSelect(program)}>
                                <img src={program.image} alt={"program.name"} className="w-[50px] h-[50px]" draggable={false} />
                                <div className="font-bold text-sm text-white">{<Translate id={program.name} />}</div>
                            </div>
                        ))}
                    </div>
    
                </div>
                <div className="relative w-full h-[40px] bg-black/50 flex items-center justify-between px-2">
                    <div className="flex items-center gap-2 whitespace-nowrap">
                        <img src={computerInfo.homeImage} alt="home" className="w-[25px] h-[25px]" />
                        <div className="text-sm font-semibold text-white">{player.name}</div>
                        <div className="flex overflow-x-auto gap-0">
                            {windows.map((window, index) => (
                                <div 
                                    key={index} 
                                    className="flex items-center justify-center w-[40px] h-[40px] relative group hover:bg-white/50 cursor-pointer"
                                    title={translateText(config, window.name, [])}
                                    onClick={() => setCurrentWindow(window)}
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
    const [computerInfo, setComputerInfo] = useState<ComputerInfo | null>({
        backgroundImage: "https://www.dojrp.com/uploads/monthly_2022_05/large.DOJRP-LSPD-PA-6.png.bc543f0c421f54fc03cbae19e505d8c8.png",
        homeImage: "nui/images/LSPD.webp"
    });
    useNuiEvent("updateComputerInfo", (data: any) => {
        setComputerInfo(data.computerInfo);
    });
    return (
        computerInfo && (
            <div className="dark w-screen h-screen absolute text-primary top-0 left-0 bg-gray-900 flex items-center justify-center">
                <AppControls />
                <Computer info={computerInfo} />
            </div>
        )
    )
}