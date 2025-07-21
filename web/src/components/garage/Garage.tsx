import { AppControls, DisplayCurrency } from "@/App";
import { Translate } from "@/providers/locale/Locale";
import { useNuiEvent } from "@/providers/nui/useNui";
import { ArrowLeft, ArrowRight, CarFront, CarFrontIcon, Plus, Save, ShoppingBasket, Trash } from "lucide-react";
import { useEffect, useState } from "react";
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
    const [isMouseDown, setIsMouseDown] = useState(false);
    const [lastMouseX, setLastMouseX] = useState(0);
    const [lastTimestamp, setLastTimestamp] = useState(0);

    useNuiEvent("selectVehicle", (data: any) => {
        setDisplayVehicle(data.vehicleInfo);
    });

    useNuiEvent("updateSelectedVehicle", (data: any) => {
        setDisplayVehicle(prev => {
            if (!prev) return prev;
            return { ...prev, ...data.vehicleInfo };
        });
    });

    useEffect(() => {
        const handleMouseMove = (e: MouseEvent) => {
            if (isMouseDown) {
                const now = Date.now();
                const currentMouseX = e.screenX;
        
                const dt = now - lastTimestamp;
                const distance = Math.abs(currentMouseX - lastMouseX);
                let speed = Math.round(distance / dt * 5);
                
                if (currentMouseX < lastMouseX) {
                    speed = speed * -1;
                }
                
                setLastMouseX(currentMouseX);
                setLastTimestamp(now);

                fetchNui("rotateMouse", {
                    distance: distance,
                    speed: speed
                });
            }
        };

        const handleMouseUp = () => {
            setIsMouseDown(false);
        };

        document.addEventListener('mousemove', handleMouseMove);
        document.addEventListener('mouseup', handleMouseUp);

        return () => {
            document.removeEventListener('mousemove', handleMouseMove);
            document.removeEventListener('mouseup', handleMouseUp);
        };
    }, [isMouseDown, lastMouseX, lastTimestamp]);

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
                    fetchNui("selectVehicle", {
                        index: parseInt((vehicleElement as HTMLElement).getAttribute('data-index') || "0"),
                    });
                }
            }
        };

        document.addEventListener('mousemove', handleMouseMove);
        document.addEventListener('mouseup', handleMouseUp);
    };

    const handleRotateMouseDown = (e: React.MouseEvent<HTMLDivElement>) => {
        setIsMouseDown(true);
        setLastMouseX(e.pageX);
        setLastTimestamp(Date.now());
    };

    return (
        <div className="relative w-full h-full select-none" onMouseDown={handleRotateMouseDown}>
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
                                        fetchNui("changeLivery", {
                                            left: true,
                                        });
                                    }}/>
                                    <div className="font-semibold text-md">
                                        #{displayVehicle.livery}
                                    </div>
                                    <ArrowRight size={16} className="cursor-pointer" onClick={() => {
                                        fetchNui("changeLivery", {
                                            left: false,
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
                                        fetchNui("toggleExtra", {
                                            index: parseInt(key),
                                            state: value,
                                        });
                                        // setDisplayVehicle(prev => {
                                        //     if (!prev) return prev;
                                        //     return {
                                        //         ...prev,
                                        //         extras: {
                                        //             ...prev.extras,
                                        //             [parseInt(key)]: !prev.extras[parseInt(key)],
                                        //         },
                                        //     };
                                        // });
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
                                            fetchNui("changeColor", {
                                                color: color,
                                                value: e.target.value,
                                            });
                                            // setDisplayVehicle(prev => {
                                            //     if (!prev) return prev;
                                            //     return {
                                            //         ...prev,
                                            //         colors: {
                                            //             ...prev.colors,
                                            //             [color]: e.target.value,
                                            //         },
                                            //     };
                                            // });
                                        }} />
                                    </div>
                                ))}
                            </div>
                            <div className="flex flex-row items-center justify-between gap-4">
                                <div className="font-semibold text-md"><Translate id={"template"} />:</div>
                                <div className="flex flex-row items-center gap-2">
                                    {displayVehicle.currentTemplate != "add_template" ? (
                                        <select className="bg-background/90 border-none pr-2" value={displayVehicle.currentTemplate || "none"} onChange={(e) => {
                                            if (e.target.value !== "none" && displayVehicle.templates[e.target.value as string]) {
                                                fetchNui("selectTemplate", {
                                                    name: e.target.value,
                                                });
                                                // setDisplayVehicle(prev => {
                                                //     if (!prev) return prev;
                                                //     return {
                                                //         ...prev,
                                                //         currentTemplate: e.target.value === "none" ? undefined : e.target.value,
                                                //         livery: displayVehicle.templates[e.target.value as string].livery,
                                                //         extras: {
                                                //             ...displayVehicle.templates[e.target.value as string].extras,
                                                //         },
                                                //         colors: displayVehicle.templates[e.target.value as string].colors,
                                                //     };
                                                // });
                                            }
                                            else {
                                                if (e.target.value !== "add_template" && e.target.value !== "none") {
                                                    fetchNui("selectTemplate", {
                                                        name: e.target.value,
                                                    });
                                                }
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
                                            setTemplateName(null);
                                            fetchNui("saveTemplate", {
                                                name: templateName,
                                                template: {
                                                    livery: displayVehicle.livery,
                                                    extras: displayVehicle.extras,
                                                    colors: displayVehicle.colors,
                                                },
                                            });
                                            setDisplayVehicle(prev => {
                                                if (!prev) return prev;
                                                return {
                                                    ...prev,
                                                    currentTemplate: "none",
                                                };
                                            });
                                            // setDisplayVehicle(prev => {
                                            //     if (!prev) return prev;
                                            //     return {
                                            //         ...prev,
                                            //         currentTemplate: templateName,
                                            //         templates: {
                                            //             ...prev.templates,
                                            //             [templateName]: {
                                            //                 ...prev.templates[templateName],
                                            //                 livery: displayVehicle.livery,
                                            //                 extras: displayVehicle.extras,
                                            //                 colors: displayVehicle.colors,
                                            //             },
                                            //         },
                                            //     };
                                            // });
                                        }
                                        else {
                                            fetchNui("saveTemplate", {
                                                name: displayVehicle.currentTemplate,
                                                template: {
                                                    livery: displayVehicle.livery,
                                                    extras: displayVehicle.extras,
                                                    colors: displayVehicle.colors,
                                                },
                                            });
                                            setDisplayVehicle(prev => {
                                                if (!prev) return prev;
                                                return {
                                                    ...prev,
                                                    currentTemplate: displayVehicle.currentTemplate,
                                                };
                                            });
                                            // setDisplayVehicle(prev => {
                                            //     if (!prev) return prev;
                                            //     return {
                                            //         ...prev,
                                            //         currentTemplate: displayVehicle.currentTemplate,
                                            //         templates: {
                                            //             ...prev.templates,
                                            //             [displayVehicle.currentTemplate as string]: {
                                            //                 ...prev.templates[displayVehicle.currentTemplate as string],
                                            //                 livery: displayVehicle.livery,
                                            //                 extras: displayVehicle.extras,
                                            //                 colors: displayVehicle.colors,
                                            //             },
                                            //         },
                                            //     };
                                            // });
                                        }
                                    }} />}
                                    {displayVehicle.currentTemplate && <Trash className="cursor-pointer" size={16} onClick={()=> {
                                        fetchNui("deleteTemplate", {
                                            name: displayVehicle.currentTemplate,
                                        });
                                    }} />}
                                </div>
                            </div>
                            <Button 
                                className="w-full gap-1 bg-green-600 hover:bg-green-700 text-white text-md" 
                                onClick={() => {
                                    fetchNui("takeVehicle", {
                                        index: displayVehicle.index,
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
    const [visible, setVisible] = useState(false);
    const updateGarageInfo = (data: any) => {
        if (data) {
            setGarageInfo(data);
            setTimeout(() => {
                setVisible(true);
            }, 10);
        }
        else {
            setVisible(false);
            setTimeout(() => {
                setGarageInfo(null);
            }, 250);
        }
    }
    useNuiEvent("updateGarageInfo", (data: any) => {
        updateGarageInfo(data.garageInfo);
    });
    useEffect(() => {
        const handleKeyDown = (event: KeyboardEvent) => {
            if (event.target instanceof HTMLInputElement || event.target instanceof HTMLTextAreaElement) return;
            if (!visible) return;
            if (event.key === "Escape") {
                fetchNui("closeGarage", {});
            }
        };

        window.addEventListener("keydown", handleKeyDown);

        return () => {
            window.removeEventListener("keydown", handleKeyDown);
        };
    });
    return (
        garageInfo && (
            <div className="dark w-screen h-screen absolute text-primary top-0 left-0 flex items-center justify-center transition-opacity duration-200 ease-in-out" style={{
                opacity: visible ? 1 : 0,
            }}>
                <AppControls />
                <Garage garageInfo={garageInfo} />
            </div>
        )
    )
}