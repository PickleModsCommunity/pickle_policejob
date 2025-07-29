import { useNuiEvent } from "@/providers/nui/useNui";
import { useEffect, useState } from "react";

type Bodycam = {
    rank: string;
    department: string;
    name: string;
}

export default function Bodycam() {
    const [visible, setVisible] = useState(false);
    const [bodycam, setBodycam] = useState<Bodycam | null>(null);
    const [date, setDate] = useState<string>(new Date().toLocaleDateString("en-US", {
        month: "2-digit",
        day: "2-digit",
    }).replace(/\//g, '-'));
    const [time, setTime] = useState<string>(new Date().toLocaleTimeString("en-US", {
        hour: "2-digit",
        minute: "2-digit",
        second: "2-digit",
        hour12: false
    }));

    const setBodycamData = (data: Bodycam | null) => {
        if (data) {
            setBodycam(data);
            setTimeout(() => {
                setVisible(true);
            }, 10);
        } else {
            setVisible(false);
            setTimeout(() => {
                setBodycam(null);
            }, 300);
        }
    }

    // useEffect(() => {
    //     setBodycamData({
    //         rank: "Officer",
    //         department: "Los Santos Police Department",
    //         name: "John Doe",
    //     })
    //     setTimeout(() => {
    //         setBodycamData(null);
    //     }, 2000);
    // }, []);

    useEffect(() => {
        let interval: NodeJS.Timeout;
        if (bodycam) {
            interval = setInterval(() => {
                setDate(new Date().toLocaleDateString("en-US", {
                    month: "2-digit",
                    day: "2-digit",
                }).replace(/\//g, '-'));
                setTime(new Date().toLocaleTimeString("en-US", {
                    hour: "2-digit",
                    minute: "2-digit",
                    second: "2-digit",
                    hour12: false
                }));
            }, 1000);
        }
        return () => {
            if (interval) clearInterval(interval);
        };
    }, [bodycam]);

    useNuiEvent("setBodycamInfo", (data) => {
        setBodycamData(data.bodycamInfo);
    });

    return bodycam && (
        <div className="px-[65px] py-[45px] select-none flex items-center gap-2 justify-end transition-opacity duration-300 " style={{
            fontFamily: "VCR",
            opacity: visible ? 1 : 0,
            color: "white",
            letterSpacing: "0.05em",
            WebkitTextStroke: "0px 0px 2px black",
            fontWeight: "bold",
        }}>
            <div className="flex flex-col items-end gap-0">
                
                <div className="text-lg font-bold">{date} {time} -0400</div>
                <div className="text-lg font-bold">{bodycam.rank.toUpperCase()} {bodycam.name.toUpperCase()}</div>
                <div className="text-lg font-bold">{bodycam.department.toUpperCase()}</div>
            </div>
            <img className="w-[75px] h-[75px]" src="/nui/images/bodycam.png" alt="Bodycam" />
        </div>
    )
}