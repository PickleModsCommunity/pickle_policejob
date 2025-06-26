import { AppControls, DisplayCurrency } from "@/App";
import { Translate } from "@/providers/locale/Locale";
import { useNuiEvent } from "@/providers/nui/useNui";
import { ArrowLeft, ArrowRight, CarFront, CarFrontIcon, Plus, Save, ShoppingBasket } from "lucide-react";
import { useState } from "react";
import { Button } from "../ui/button";
import { fetchNui } from "@/providers/nui/fetchNui";

type DisplayVehicle = {
    index: number;
    currentTemplate?: string;
    liveryCount: number;
    livery: number;
    extras: {
        [key: number]: boolean;
    };
    colors: {
        primary: number;
        secondary: number;
    };
    templates: {
        [key: string]: {
            livery: number;
            extras: {
                [key: number]: boolean;
            };
            colors: {
                primary: number;
                secondary: number;
            };
        };
    };
}

type VehicleInfo = {
    label: string;
    image?: string;
    price?: number;
    permissions: string[];
}

type GarageInfo = {
    vehicles: VehicleInfo[];
}

function Garage({garageInfo}: {garageInfo: GarageInfo}) {
    const colorOrder = ["primary", "secondary"];
    const [displayVehicle, setDisplayVehicle] = useState<DisplayVehicle | null>(null);
    const [templateName, setTemplateName] = useState<string | null>(null);
    const handleWheel = (e: React.WheelEvent) => {
        const container = e.currentTarget;
        container.scrollLeft += e.deltaY;
    };
    
    const handleMouseDown = (e: React.MouseEvent<HTMLDivElement>) => {
        const container = e.currentTarget;
        const startX = e.pageX - container.offsetLeft;
        const scrollLeft = container.scrollLeft;
        let isDragging = false;

        const handleMouseMove = (e: MouseEvent) => {
            const x = e.pageX - container.offsetLeft;
            const walk = (x - startX) * 2;
            if (Math.abs(walk) > 10) {
                isDragging = true;
            }
            container.scrollLeft = scrollLeft - walk;
        };

        const handleMouseUp = (e: MouseEvent) => {
            document.removeEventListener('mousemove', handleMouseMove);
            document.removeEventListener('mouseup', handleMouseUp);

            if (!isDragging) {
                const target = e.target as HTMLElement;
                const vehicleElement = target.closest('.vehicle-card');
                if (vehicleElement) {
                    const container = vehicleElement.parentElement;
                    if (!container) return;

                    const containerWidth = container.clientWidth;
                    const vehicleLeft = (vehicleElement as HTMLElement).offsetLeft;
                    const vehicleWidth = (vehicleElement as HTMLElement).clientWidth;
                    const scrollPosition = vehicleLeft - (containerWidth / 2) + (vehicleWidth / 2);
                    
                    container.scrollTo({
                        left: scrollPosition,
                        behavior: 'smooth'
                    });
                    setDisplayVehicle({
                        index: parseInt((vehicleElement as HTMLElement).getAttribute('data-index') || "0"),
                        currentTemplate: undefined,
                        liveryCount: 12,
                        livery: 1,
                        extras: {
                            [0]: false,
                            [1]: false,
                            [2]: false,
                            [3]: false,
                            [4]: false,
                            [5]: false,
                            [6]: false,
                            [7]: false,
                            [8]: false,
                            [9]: false,
                            [10]: false,
                            [11]: false,
                            [12]: false,
                            [13]: false,
                            [14]: false,
                        },
                        colors: {
                            primary: 0,
                            secondary: 0,
                        },
                        templates: {
                            ["Undercover"]: {
                                livery: 1,
                                extras: {
                                    [11]: true,
                                },
                                colors: {
                                    primary: 0,
                                    secondary: 0,
                                },
                            },
                        }
                    });
                }
            }
        };

        document.addEventListener('mousemove', handleMouseMove);
        document.addEventListener('mouseup', handleMouseUp);
    };

    return (
        <div className="relative w-full h-full select-none">
            <div className="absolute bottom-0 left-0 w-full gap-4 flex flex-col items-end">
                {
                    displayVehicle && (
                        <div className="p-4 mr-4 bg-background/90 rounded-md flex flex-col gap-2">
                            <div className="flex flex-row items-center justify-between gap-16">
                                <div className="font-semibold text-xl">
                                    {garageInfo.vehicles[displayVehicle.index].label}
                                </div>
                                <div className="font-semibold text-md text-green-500">
                                    {garageInfo.vehicles[displayVehicle.index].price ? <DisplayCurrency value={garageInfo.vehicles[displayVehicle.index].price || 0} /> : <Translate callback={(rawText: string) => {
                                        return rawText.toUpperCase();
                                    }} id="free"/>}
                                    
                                </div>
                            </div>
                            <hr></hr>
                            <div className="flex flex-row items-center justify-between gap-4">
                                <div className="font-semibold text-md"><Translate id={"livery"} /></div>
                                <div className="flex flex-row items-center gap-2">
                                    <ArrowLeft size={16} className="cursor-pointer" onClick={() => {
                                        setDisplayVehicle(prev => {
                                            if (!prev) return prev;
                                            return {
                                                ...prev,
                                                livery: prev.livery - 1 < 1 ? displayVehicle.liveryCount : prev.livery - 1,
                                            };
                                        });
                                    }}/>
                                    <div className="font-semibold text-md">
                                        #{displayVehicle.livery}
                                    </div>
                                    <ArrowRight size={16} className="cursor-pointer" onClick={() => {
                                        setDisplayVehicle(prev => {
                                            if (!prev) return prev;
                                            return {
                                                ...prev,
                                                livery: prev.livery + 1 > displayVehicle.liveryCount ? 1 : prev.livery + 1,
                                            };
                                        });
                                    }}/>
                                </div>
                            </div>
                            <div className="font-semibold text-md"><Translate id={"extras"} />:</div>
                            <div className="grid grid-cols-7 gap-2">
                                {Object.entries(displayVehicle.extras).map(([key, value], index) => (
                                    <div key={index} className="flex flex-row items-center justify-center gap-2 cursor-pointer rounded-md p-2 transition-all duration-200 ease-in-out" style={{
                                        backgroundColor: value ? "rgba(255, 255, 255, 0.20)" : "rgba(255, 255, 255, 0.05)",
                                    }} onClick={() => {
                                        setDisplayVehicle(prev => {
                                            if (!prev) return prev;
                                            return {
                                                ...prev,
                                                extras: {
                                                    ...prev.extras,
                                                    [parseInt(key)]: !prev.extras[parseInt(key)],
                                                },
                                            };
                                        });
                                    }}>
                                        <div className="font-bold text-xs text-center">#{index + 1}</div>
                                    </div>
                                ))}
                            </div>
                            <div className="flex flex-row items-center justify-between gap-4">
                                {colorOrder.map((color, index) => (
                                    <div key={index} className="flex flex-row items-center gap-2">
                                        <div className="font-semibold text-md"><Translate id={"color_"+color} /></div>
                                        <input type="color" className="bg-transparent border-none" value={displayVehicle.colors[color as keyof typeof displayVehicle.colors]} onChange={(e) => {
                                            setDisplayVehicle(prev => {
                                                if (!prev) return prev;
                                                return {
                                                    ...prev,
                                                    colors: {
                                                        ...prev.colors,
                                                        [color]: e.target.value,
                                                    },
                                                };
                                            });
                                        }} />
                                    </div>
                                ))}
                            </div>
                            <div className="flex flex-row items-center justify-between gap-4">
                                <div className="font-semibold text-md"><Translate id={"template"} />:</div>
                                <div className="flex flex-row items-center gap-2">
                                    {displayVehicle.currentTemplate != "add_template" ? (
                                        <select className="bg-background/90 border-none pr-2" value={displayVehicle.currentTemplate || "none"} onChange={(e) => {
                                            if (displayVehicle.templates[e.target.value as string]) {
                                                setDisplayVehicle(prev => {
                                                    if (!prev) return prev;
                                                    return {
                                                        ...prev,
                                                        currentTemplate: e.target.value === "none" ? undefined : e.target.value,
                                                        livery: displayVehicle.templates[e.target.value as string].livery,
                                                        extras: {
                                                            ...displayVehicle.templates[e.target.value as string].extras,
                                                        },
                                                        colors: displayVehicle.templates[e.target.value as string].colors,
                                                    };
                                                });
                                            }
                                            else {
                                                setDisplayVehicle(prev => {
                                                    if (!prev) return prev;
                                                    return {
                                                        ...prev,
                                                        currentTemplate: e.target.value === "none" ? undefined : e.target.value,
                                                    };
                                                });
                                            }
                                        }}>
                                            <option className="bg-background/90" value="none"><Translate id={"no_template"} /></option>
                                            <option className="bg-background/90" value="add_template">+ <Translate id={"add_template"} /></option>
                                            {Object.entries(displayVehicle.templates).map(([key, value], index) => (
                                                <option className="bg-background/90" key={index} value={key}>{key}</option>
                                            ))}
                                        </select>
                                    ) : (
                                        <input type="text" className="bg-secondary/50 border-none px-2 rounded-md" value={templateName || ""} onChange={(e) => {
                                            setTemplateName(e.target.value);
                                        }}/>
                                    )}

                                    {displayVehicle.currentTemplate && <Save className="cursor-pointer" size={16} onClick={()=> {
                                        if (templateName) {
                                            setDisplayVehicle(prev => {
                                                if (!prev) return prev;
                                                return {
                                                    ...prev,
                                                    currentTemplate: templateName,
                                                    templates: {
                                                        ...prev.templates,
                                                        [templateName]: {
                                                            ...prev.templates[templateName],
                                                            livery: displayVehicle.livery,
                                                            extras: displayVehicle.extras,
                                                            colors: displayVehicle.colors,
                                                        },
                                                    },
                                                };
                                            });
                                        }
                                        else {
                                            setDisplayVehicle(prev => {
                                                if (!prev) return prev;
                                                return {
                                                    ...prev,
                                                    currentTemplate: displayVehicle.currentTemplate,
                                                    templates: {
                                                        ...prev.templates,
                                                        [displayVehicle.currentTemplate as string]: {
                                                            ...prev.templates[displayVehicle.currentTemplate as string],
                                                            livery: displayVehicle.livery,
                                                            extras: displayVehicle.extras,
                                                            colors: displayVehicle.colors,
                                                        },
                                                    },
                                                };
                                            });
                                        }
                                    }} />}
                                </div>
                            </div>
                            <Button 
                                className="w-full gap-1 bg-green-600 hover:bg-green-700 text-white text-md" 
                                onClick={() => {
                                    fetchNui("takeVehicle", {
                                        vehicle: displayVehicle,
                                    });
                                }}
                            >
                                <Translate id={"take_vehicle"}></Translate>
                            </Button>
                        </div>
                    )
                }
                <div 
                    className="flex flex-row w-full bg-background/90 p-4 gap-2 overflow-x-auto scroll-smooth"
                    onWheel={handleWheel}
                    onMouseDown={handleMouseDown}
                >
                    {garageInfo.vehicles.map((vehicle, index) => (
                        <div 
                            key={index}
                            data-index={index}
                            className="vehicle-card relative min-w-[400px] max-w-[400px] h-[200px] cursor-pointer hover:bg-white/5 rounded-md transition-all duration-200 ease-in-out"
                            style={displayVehicle?.index === index ? {
                                backgroundColor: "rgba(255, 255, 255, 0.1)",
                            } : {}}
                        >
                            {vehicle.image && (
                                <div className="absolute top-0 left-0 w-full h-full pointer-events-none p-4">
                                    <img className="w-full h-full object-fit" src={vehicle.image} alt={vehicle.label} />
                                </div>
                            )}
                            <div className="flex flex-col gap-2">
                                <div className="absolute top-0 right-0 p-2">
                                    {(vehicle.price && vehicle.price > 0) ? (
                                        <div className="font-semibold text-sm text-green-500">
                                            <DisplayCurrency value={vehicle.price} />
                                        </div>
                                    ) : null}
                                </div>
                                <div className="absolute bottom-0 right-0 p-2">
                                    <div className="font-semibold text-xl">
                                        {vehicle.label}
                                    </div>
                                </div>
                            </div>
                        </div>
                    ))}
                </div>
            </div>
        </div>
    )
}

export function GarageContainer() {
    const [garageInfo, setGarageInfo] = useState<GarageInfo | null>(null);
    useNuiEvent("updateGarageInfo", (data: any) => {
        setGarageInfo(data.garageInfo);
    });
    return (
        garageInfo && (
            <div className="dark w-screen h-screen absolute text-primary top-0 left-0 bg-gray-900 flex items-center justify-center">
                <AppControls />
                <Garage garageInfo={garageInfo} />
            </div>
        )
    )
}