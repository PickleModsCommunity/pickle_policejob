import { useLocale } from "@/providers/locale/Locale";
import { useNuiEvent } from "@/providers/nui/useNui";
import { useEffect, useRef, useState } from "react";
import { cn } from "@/lib/utils";
import { CSSProperties } from "react";

export type CameraState = "idle" | "scanning" | "match" | "no_match"

export type CameraEvidence = {
  label: string;
  image: string;
}

export default function Camera() {
  const [show, setShow] = useState(false)
  const translate = useLocale()
  const [cameraState, setCameraState] = useState<CameraState | null>(null);
  const [evidence, setEvidence] = useState<CameraEvidence[]>([]);
  const [loadedImages, setLoadedImages] = useState<{[key: number]: boolean}>({});
  const ref = useRef<HTMLDivElement>(null)
  const textStyle = {
    WebkitTextStroke: "0px 0px 2px black",
  }
//   useEffect(() => {
//     setShow(true)
//     setCameraState("idle")
//   }, [])
  let cameraStateSettings = {
    "idle": {content: (
      <div className="flex items-center text-[30px] font-bold outlined text-white" style={textStyle}>
        {translate("camera_state_idle_1")} 
        <KeyboardIcon style={{margin: "0 15px", padding: "15px 15px", fontSize: "20px", textShadow: "none"}} text={"SPACEBAR"}/> 
        {translate("camera_state_idle_2")}
      </div>
    )},
    "scanning": {content: (
      <div className="flex items-center text-[30px] font-bold text-yellow-400 outlined" style={textStyle}>
        {translate("camera_state_scanning")}
      </div>
    )},
    "match": {content: (
      <div className="flex items-center text-[30px] font-bold text-green-400 outlined" style={textStyle}>
        {translate("camera_state_match")}
      </div>
    )},
    "no_match": {content: (
      <div className="flex items-center text-[30px] font-bold text-red-400 outlined" style={textStyle}>
        {translate("camera_state_no_match")}
      </div>
    )},
  }

  useNuiEvent("setCameraState", function(data) {
    if (data.cameraState) {
      setCameraState(data.cameraState)
      setTimeout(() => {
        setShow(true)
      }, 10)
    }
    else {
      setShow(false)
      setTimeout(() => {
        setCameraState(null)
        setLoadedImages({})
        setEvidence([])
      }, 200)
    }
  })
  useNuiEvent("setCameraEvidence", function(data) {
    setEvidence(data.evidence)
  })

  useEffect(() => {
    if (ref.current) {
      ref.current.scrollTop = -ref.current.scrollHeight
    }
  }, [evidence])

  return (
    (cameraState) && (
      <div className={cn(
        "relative top-0 left-0 w-full h-full",
        show ? "opacity-100" : "opacity-0"
      )} style={{ 
        backgroundImage: 'url("/nui/images/camera_overlay.png")',
        backgroundSize: "cover",
        backgroundPosition: "center",
        backgroundRepeat: "no-repeat",
      }}>
        <div className={cn(
          "absolute bottom-[11rem] left-1/2 translate-x-[-50%] translate-y-0 h-[200px]",
          "flex flex-col items-center justify-center",
          "transition-opacity duration-200 opacity-100"
        )}>
          {(cameraState && cameraStateSettings[cameraState]) && (
            cameraStateSettings[cameraState].content
          )}
          {cameraState === "idle" && (
            <div className="flex flex-col w-full gap-2">
                <hr/>
                <div className="flex flex-row justify-center gap-12 w-full">
                    <div className="flex items-center text-[15px] font-bold outlined text-white" style={textStyle}>
                        <KeyboardIcon style={{margin: "0 10px 0 0", padding: "12px 10px", fontSize: "15px", textShadow: "none"}} text={"E"}/> 
                        {translate("camera_take_photo")} 
                    </div>
                    <div className="flex items-center text-[15px] font-bold outlined text-white" style={textStyle}>
                        <KeyboardIcon style={{margin: "0 10px 0 0", padding: "12px 10px", fontSize: "15px", textShadow: "none"}} text={"S"}/> 
                        {translate("camera_save_evidence")} 
                    </div>
                </div>
            </div>
          )}
        </div>
        <div className="dark absolute top-[0] right-2 py-[8rem] w-[300px] h-[100%]">
            <div ref={ref} className="h-full w-full rounded-md flex flex-col-reverse gap-2 overflow-hidden px-2">
                {evidence.map((evidence, index) => (
                    <div 
                      key={index} 
                      className="flex items-center justify-center gap-2 relative"
                      style={{
                        animation: 'slideInFromRight 0.3s ease-out forwards',
                        transform: 'translateX(100%)',
                        opacity: 0
                      }}
                    >
                        <div className="relative w-[284px] h-[159px] rounded-md bg-background">
                          {!loadedImages[index] && (
                            <div className="absolute inset-0 flex items-center justify-center">
                              <div className="w-8 h-8 border-4 border-white border-t-transparent rounded-full animate-spin"></div>
                            </div>
                          )}
                          <img 
                            src={evidence.image} 
                            alt={evidence.label} 
                            className="w-full h-full rounded-md" 
                            onLoad={() => setLoadedImages(prev => ({...prev, [index]: true}))}
                          />
                        </div>
                        <div className="absolute top-0 left-0 w-full h-[30px] rounded-b-md font-semibold text-white flex items-center px-2">
                          #{index + 1}
                        </div>
                        <div className="absolute bottom-0 left-0 w-full h-[30px] bg-background/50 rounded-b-md font-semibold text-white flex items-center px-2">
                          {evidence.label}
                        </div>
                        <style>{`
                          @keyframes slideInFromRight {
                            from {
                              transform: translateX(100%);
                              opacity: 0;
                            }
                            to {
                              transform: translateX(0);
                              opacity: 1;
                            }
                          }
                        `}</style>
                    </div>
                ))}
            </div>
        </div>
      </div>
    )
  )
}

export function KeyboardIcon({text, style} : {text: string, style?: CSSProperties}) {
  return (
    <div className={cn(
      "flex items-center bg-white text-black font-bold text-xs rounded",
      "px-[10px] h-[18px] mx-[5px]"
    )} style={style}>
      {text}
    </div>
  );
}