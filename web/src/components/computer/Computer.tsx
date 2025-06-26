import { AppControls } from "@/App";
import { Translate } from "@/providers/locale/Locale";
import { useNuiEvent } from "@/providers/nui/useNui";
import { usePlayer } from "@/providers/player/player";
import { MinusIcon, X } from "lucide-react";
import { useEffect, useState } from "react";
import HomePage from "./Homepage";
import RosterPage from "./RosterPage";
import EvidencePage from "./EvidencePage";
import SettingsPage from "./SettingsPage";

type ComputerInfo = {
    backgroundImage: string;
    homeImage: string;
}

function Computer({computerInfo}: {computerInfo: ComputerInfo}) {
    const {player} = usePlayer();
    const programs = [
        {
            id: "homepage",
            name: <Translate id="page_homepage" />,
            image: "nui/images/LSPD.webp"
        },
        {
            id: "roster",
            name: <Translate id="page_roster" />,
            image: "nui/images/LSPD.webp"
        },
        {
            id: "evidence",
            name: <Translate id="page_evidence" />,
            image: "nui/images/LSPD.webp"
        },
        {
            id: "settings",
            name: <Translate id="page_settings" />,
            image: "nui/images/LSPD.webp"
        },
    ]
    const [currentProgram, setCurrentProgram] = useState<typeof programs[number] | null>(null);
    const [currentDateTime, setCurrentDateTime] = useState<Date>(new Date());
    useEffect(() => {
        const interval = setInterval(() => {
            setCurrentDateTime(new Date());
        }, 1000);
        return () => clearInterval(interval);
    }, []);
    return (
        <div className="relative w-[1280px] h-[720px] flex flex-col items-center justify-center" style={{
            backgroundImage: `url(${computerInfo.backgroundImage})`,
            backgroundSize: "cover",
            backgroundPosition: "center",
            backgroundRepeat: "no-repeat",
        }}>
            <div className="relative w-full h-[calc(100%-40px)]">
                {currentProgram && (
                    <div className="absolute top-[50%] left-[50%] translate-x-[-50%] translate-y-[-50%] w-[75%] h-[75%] z-10 bg-background">
                        <div className="relative w-full h-[30px] bg-secondary flex items-center justify-between select-none">
                            <div className="flex items-center justify-center gap-2 pl-2">
                                <img src={currentProgram.image} alt={""} className="w-[15px] h-[15px]" />
                                <div className="font-semibold text-sm text-white">{currentProgram.name}</div>
                            </div>
                            <div className="flex items-center justify-center gap-2 hover:bg-red-500 transition-all duration-300 h-[30px] w-[30px] cursor-pointer" onClick={() => setCurrentProgram(null)}>
                                <X/>
                            </div>
                        </div>
                        <div className="w-full h-[calc(100%-30px)]">
                            {currentProgram.id === "homepage" && <HomePage />}
                            {currentProgram.id === "roster" && <RosterPage />}
                            {currentProgram.id === "evidence" && <EvidencePage />}
                            {currentProgram.id === "settings" && <SettingsPage />}
                        </div>
                    </div>
                )}
                <div className="absolute top-0 left-0 flex flex-col gap-2 p-4 select-none">
                    {programs.map((program, index) => (
                        <div className="flex flex-col items-center justify-center gap-1 hover:bg-background/25 rounded-sm py-2 px-1 cursor-pointer" key={index} onClick={() => setCurrentProgram(program)}>
                            <img src={program.image} alt={"program.name"} className="w-[50px] h-[50px]" draggable={false} />
                            <div className="font-bold text-sm text-white">{program.name}</div>
                        </div>
                    ))}
                </div>
  
            </div>
            <div className="w-full h-[40px] bg-black/50 flex items-center justify-between px-2">
                <div className="flex items-center justify-center gap-2">
                    <img src={computerInfo.homeImage} alt="home" className="w-[25px] h-[25px]" />
                    <div className="text-sm font-semibold text-white">{player.name}</div>
                </div>
                <div className="flex flex-col items-end justify-center">
                    <div className="text-xs text-white">{currentDateTime.toLocaleTimeString([], {hour: '2-digit', minute: '2-digit'})}</div>
                    <div className="text-xs text-white">{currentDateTime.toLocaleDateString()}</div>
                </div>
            </div>
        </div>
    )
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
                <Computer computerInfo={computerInfo} />
            </div>
        )
    )
}