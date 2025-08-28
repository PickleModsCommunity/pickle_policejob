import { AppControls, DisplayCurrency, GetItemImage, GetItemLabel } from "@/App";
import { useConfig } from "@/providers/config";
import { Translate } from "@/providers/locale/Locale";
import { fetchNui } from "@/providers/nui/fetchNui";
import { useNuiEvent } from "@/providers/nui/useNui";
import { LockIcon, ShoppingBasket, ShoppingCart } from "lucide-react";
import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";

type ArmoryItem = {
    label: string;
    image: string;
    name: string;
    count: number;
    itemType?: string;
    price?: number;
    maxCount?: number;
    permissions: string[];
}

type ArmoryInfo = {
    items: ArmoryItem[];
}

export function ItemDisplay({item}: {item: ArmoryItem | {label?: string, image?: string, name: string, itemType?: string}}) {
    return (
        <div className="relative w-24 h-24 bg-background/50 rounded-md overflow-hidden select-none flex flex-col gap-0 items-center justify-between transition-transform duration-200 ease-in-out">
            <div className="w-full h-full flex flex-col gap-0 items-center justify-center absolute top-0 left-0 p-1">
                <img src={item.image ? item.image : GetItemImage(item.name)} alt={""} className="w-full h-full object-contain" draggable={false} onError={(e) => {
                    const target = e.target as HTMLImageElement;
                    target.style.display = "none"; // hides the image
                }} />                            
            </div>
            <div className="w-full z-10 px-[4px] py-[2px] bg-background/50 mt-auto">
                    <div className="font-semibold text-xs text-center truncate">
                        {item.label ? (
                            item.label
                        ) : (
                            <GetItemLabel item={(item.name || item.itemType) as string} />
                        )}
                    </div>
                </div>
        </div>
    )
}

function Armory({armoryInfo}: {armoryInfo: ArmoryInfo}) {
    const { config } = useConfig();
    const [items, setItems] = useState<ArmoryItem[]>(armoryInfo.items);
    const [hoveredItems, setHoveredItems] = useState<{[key: number]: ArmoryItem}>({});
    const [renderedItems, setRenderedItems] = useState<{[key: number]: ArmoryItem}>({});
    const hasPermission = (permissions: string[]) => {
        if (permissions.length === 0) return true;
        return permissions.some(permission => config.permissions.some((p: any) => p.name === permission));
    }
    useNuiEvent("updateArmoryItems", (data: any) => {
        setItems(data.items);
    });

    const handleItemHover = (item: ArmoryItem, index: number) => {
        setHoveredItems(prev => ({ ...prev, [index]: item }));
        setRenderedItems(prev => ({ ...prev, [index]: item }));
    };

    const handleItemLeave = (index: number) => {
        setHoveredItems(prev => {
            const newState = { ...prev };
            delete newState[index];
            return newState;
        });
        // Delay unmounting to allow fade-out animation
        setTimeout(() => {
            setRenderedItems(prev => {
                const newState = { ...prev };
                delete newState[index];
                return newState;
            });
        }, 250); // Match the CSS transition duration
    };

    return (
        <div className='flex flex-col absolute px-4 py-4 gap-4 rounded-md top-[50%] left-[50%] translate-x-[-50%] translate-y-[-50%] select-none' style={{
            transition: "opacity 0.25s ease-in-out",
        }}>
            <div className="grid grid-cols-5 gap-2 items-center overflow-y-auto max-h-[350px] px-2">
                {Array.from({ length: Math.ceil(items.length / 5) * 5 }).map((_, index) => {
                    const item = items[index];
                    if (!item) {
                        return (
                            <div key={index} className="w-24 h-24 bg-background/50 rounded-md flex items-center justify-center">
                                
                            </div>
                        )
                    }
                    return (
                        <div 
                            key={index} 
                            className="relative w-24 h-24 bg-background/50 rounded-md overflow-hidden flex flex-col gap-0 items-center justify-between transition-transform duration-200 ease-in-out" style={{
                            }}
                            onMouseEnter={() => handleItemHover(item, index)}
                            onMouseLeave={() => handleItemLeave(index)}
                        >
                            <div className="w-full z-10 px-[4px] py-[2px] flex justify-end">
                                {(item.price && item.price > 0) ? (
                                    <div className="font-semibold text-xs text-green-500">
                                        <DisplayCurrency value={item.price} />
                                    </div>
                                ) : null}
                            </div>
                            {item.image ? (
                                <img src={item.image} alt={""} className="p-[10px] max-h-14" draggable={false} onError={(e) => {
                                    const target = e.target as HTMLImageElement;
                                    target.style.display = "none"; // hides the image
                                }} />  
                            ) : (
                                <img src={GetItemImage(item.name)} alt={""} className="w-14 h-14" draggable={false} onError={(e) => {
                                    const target = e.target as HTMLImageElement;
                                    target.style.display = "none"; // hides the image
                                }} />                            
                            )}
                            <div className="w-full z-10 px-[4px] py-[2px] bg-background/50">
                                <div className="font-semibold text-xs text-center truncate">
                                    {item.label ? (
                                        item.label
                                    ) : (
                                        <GetItemLabel item={(item.name || item.itemType) as string} />
                                    )}
                                </div>
                            </div>
                            {hasPermission(item.permissions || []) ?
                                <div className="absolute top-0 left-0 w-full h-full z-[20] bg-background/75 rounded-md" style={{
                                    transition: "opacity 0.25s ease-in-out",
                                    opacity: hoveredItems[index] ? 1 : 0,
                                    pointerEvents: hoveredItems[index] ? "auto" : "none",
                                }}>
                                    {renderedItems[index] && (
                                        <div className="flex flex-col p-2 gap-2 items-center justify-center h-full">
                                            <div className="relative w-full">
                                                <span className="absolute top-[50%] left-[5%] translate-x-[5%] translate-y-[-50%] font-semibold text-xs text-center">x</span>
                                                <input type="number" className="w-full pl-3 h-5 rounded-sm bg-secondary text-xs" value={renderedItems[index]?.count} min={1} max={renderedItems[index]?.maxCount || 1000000} onChange={(e) => {
                                                    setRenderedItems(prev => ({ ...prev, [index]: { ...prev[index], count: Math.min(Math.max(1, parseInt(e.target.value)), renderedItems[index]?.maxCount || 1000000) } }));
                                                }} />
                                            </div>
                                            {renderedItems[index].price ? (
                                                <div className="font-semibold text-xs text-center">
                                                    <DisplayCurrency value={(renderedItems[index].price || 0) * (renderedItems[index].count || 1)} />
                                                </div>
                                            ) : null}
                                            <Button 
                                                className="w-full h-6  gap-1 bg-green-600 hover:bg-green-700 text-white text-xs" 
                                                onClick={() => {
                                                    fetchNui("buyArmoryItem", {
                                                        itemName: renderedItems[index].name,
                                                        quantity: renderedItems[index].count,
                                                    });
                                                }}
                                            >
                                                <ShoppingBasket className="w-3 h-3" />
                                                <Translate id={renderedItems[index].price ? "purchase" : "free"}></Translate>
                                            </Button>
                                        </div>
                                    )}
                                </div>
                             : (
                                <div className="absolute top-0 left-0 w-full h-full z-[20] bg-background/75 rounded-md flex items-center justify-center" style={{
                                    pointerEvents: "none",
                                }}>
                                    <LockIcon size={24} className="text-zinc-400" />
                                </div>
                            )}
                        </div>
                    );
                })}
            </div>
            <div className="font-semibold text-sm text-center">
                <Translate id="armory_desc" />
            </div>
        </div>
    )
}

export default function ArmoryContainer() {
    const [armoryInfo, setArmoryInfo] = useState<ArmoryInfo | null>( true ? null :
        {
            items: [
                {
                    label: "AR-15",
                    image: "/nui/images/weapons/ar15.png",
                    name: "weapon_ar15",
                    count: 1,
                    price: 1000,
                    permissions: ["Rifle Certified"],
                }
            ]
        }
    );
    const [visible, setVisible] = useState(false);
    const updateArmoryInfo = (data: any) => {
        if (data) {
            setArmoryInfo(data);
            setTimeout(() => {
                setVisible(true);
            }, 10);
        } else {
            setVisible(false);
            setTimeout(() => {
                setArmoryInfo(null);
            }, 250);
        }
    }
    useEffect(() => {
        const handleKeyDown = (event: KeyboardEvent) => {
            if (event.target instanceof HTMLInputElement || event.target instanceof HTMLTextAreaElement) return;
            if (!visible) return;
            if (event.key === "Escape") {
                fetchNui("closeArmory", {});
            }
        };

        window.addEventListener("keydown", handleKeyDown);

        return () => {
            window.removeEventListener("keydown", handleKeyDown);
        };
    });
    useNuiEvent("updateArmoryInfo", (data: any) => {
        updateArmoryInfo(data.armoryInfo);
    });
    return (
        armoryInfo && (
            <div className="dark w-screen h-screen absolute text-primary top-0 left-0 flex items-center justify-center transition-opacity duration-200 ease-in-out" style={{
                opacity: visible ? 1 : 0,
            }}>
                <AppControls />
                <Armory armoryInfo={{
                    items: armoryInfo.items,
                }} />
            </div>
        )
    )
}