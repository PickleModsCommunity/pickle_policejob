import { AppControls, DisplayCurrency, GetItemImage, GetItemLabel } from "@/App";
import { useConfig } from "@/providers/config";
import { Translate } from "@/providers/locale/Locale";
import { fetchNui } from "@/providers/nui/fetchNui";
import { useNuiEvent } from "@/providers/nui/useNui";
import { LockIcon, ShoppingBasket, ShoppingCart } from "lucide-react";
import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";
import { usePlayer } from "@/providers/player/player";

type ArmoryItem = {
    label: string;
    image: string;
    name: string;
    count: number;
    itemType?: string;
    price?: number;
    maxCount?: number;
    permissions?: string[];
}

type ArmoryInfo = {
    items: ArmoryItem[];
}

function Armory({armoryInfo}: {armoryInfo: ArmoryInfo}) {
    const { config } = useConfig();
    const { player, hasPermission } = usePlayer();
    const [items, setItems] = useState<ArmoryItem[]>(armoryInfo.items);
    const [hoveredItems, setHoveredItems] = useState<{[key: number]: ArmoryItem}>({});
    const [renderedItems, setRenderedItems] = useState<{[key: number]: ArmoryItem}>({});
    
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
                                transform: hasPermission(item.permissions || []) ? (hoveredItems[index] ? "scale(1.05)" : "scale(1)") : "scale(1)",
                            }}
                            onMouseEnter={() => handleItemHover(item, index)}
                            onMouseLeave={() => handleItemLeave(index)}
                        >
                            <div className="w-full z-10 px-[4px] py-[2px] flex justify-end">
                                {item.price && (
                                    <div className="font-semibold text-xs text-green-500">
                                        <DisplayCurrency value={item.price} />
                                    </div>
                                )}
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
                                            <div className="font-semibold text-xs text-center">
                                                <DisplayCurrency value={(renderedItems[index].price || 0) * (renderedItems[index].count || 1)} />
                                            </div>
                                            <Button 
                                                className="w-full h-6  gap-1 bg-green-600 hover:bg-green-700 text-white text-xs" 
                                                onClick={() => {
                                                    fetchNui("buyArmoryItem", {
                                                        itemName: renderedItems[index].name,
                                                        quantity: renderedItems[index].count,
                                                        price: renderedItems[index].price,
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
    const [armoryInfo, setArmoryInfo] = useState<ArmoryInfo>({
        items: [
            {
                label: "Test",
                image: GetItemImage("test"),
                name: "test",
                count: 1,
                price: 1000000,
                permissions: []
            },
            {
                label: "Rifle",
                image: GetItemImage("rifle"),
                name: "rifle",
                count: 1,
                price: 2000000,
                maxCount: 10,
                permissions: ["Rifle Certified"]
            },
            {
                label: "Test",
                image: GetItemImage("test"),
                name: "test",
                count: 1,
                price: 1000000,
                permissions: []
            },
            {
                label: "Rifle",
                image: GetItemImage("rifle"),
                name: "rifle",
                count: 1,
                price: 2000000,
                maxCount: 10,
                permissions: ["Rifle Certified"]
            },
            {
                label: "Test",
                image: GetItemImage("test"),
                name: "test",
                count: 1,
                price: 1000000,
                permissions: []
            },
            {
                label: "Rifle",
                image: GetItemImage("rifle"),
                name: "rifle",
                count: 1,
                price: 2000000,
                maxCount: 10,
                permissions: ["Rifle Certified"]
            },
            {
                label: "Test",
                image: GetItemImage("test"),
                name: "test",
                count: 1,
                price: 1000000,
                permissions: []
            },
            {
                label: "Rifle",
                image: GetItemImage("rifle"),
                name: "rifle",
                count: 1,
                price: 2000000,
                maxCount: 10,
                permissions: ["Rifle Certified"]
            },
            {
                label: "Test",
                image: GetItemImage("test"),
                name: "test",
                count: 1,
                price: 1000000,
                permissions: []
            },
            {
                label: "Rifle",
                image: GetItemImage("rifle"),
                name: "rifle",
                count: 1,
                price: 2000000,
                maxCount: 10,
                permissions: ["Rifle Certified"]
            },
            {
                label: "Test",
                image: GetItemImage("test"),
                name: "test",
                count: 1,
                price: 1000000,
                permissions: []
            },
            {
                label: "Rifle",
                image: GetItemImage("rifle"),
                name: "rifle",
                count: 1,
                price: 2000000,
                maxCount: 10,
                permissions: ["Rifle Certified"]
            },
            {
                label: "Test",
                image: GetItemImage("test"),
                name: "test",
                count: 1,
                price: 1000000,
                permissions: []
            },
            {
                label: "Rifle",
                image: GetItemImage("rifle"),
                name: "rifle",
                count: 1,
                price: 2000000,
                maxCount: 10,
                permissions: ["Rifle Certified"]
            },
            {
                label: "Test",
                image: GetItemImage("test"),
                name: "test",
                count: 1,
                price: 1000000,
                permissions: []
            },
            {
                label: "Rifle",
                image: GetItemImage("rifle"),
                name: "rifle",
                count: 1,
                price: 2000000,
                maxCount: 10,
                permissions: ["Rifle Certified"]
            },
            {
                label: "Test",
                image: GetItemImage("test"),
                name: "test",
                count: 1,
                price: 1000000,
                permissions: []
            },
            {
                label: "Rifle",
                image: GetItemImage("rifle"),
                name: "rifle",
                count: 1,
                price: 2000000,
                maxCount: 10,
                permissions: ["Rifle Certified"]
            },
            {
                label: "Test",
                image: GetItemImage("test"),
                name: "test",
                count: 1,
                price: 1000000,
                permissions: []
            },
            {
                label: "Rifle",
                image: GetItemImage("rifle"),
                name: "rifle",
                count: 1,
                price: 2000000,
                maxCount: 10,
                permissions: ["Rifle Certified"]
            },
            {
                label: "Test",
                image: GetItemImage("test"),
                name: "test",
                count: 1,
                price: 1000000,
                permissions: []
            },
            {
                label: "Rifle",
                image: GetItemImage("rifle"),
                name: "rifle",
                count: 1,
                price: 2000000,
                maxCount: 10,
                permissions: ["Rifle Certified"]
            },
            {
                label: "Test",
                image: GetItemImage("test"),
                name: "test",
                count: 1,
                price: 1000000,
                permissions: []
            },
            {
                label: "Rifle",
                image: GetItemImage("rifle"),
                name: "rifle",
                count: 1,
                price: 2000000,
                maxCount: 10,
                permissions: ["Rifle Certified"]
            },
            {
                label: "Test",
                image: GetItemImage("test"),
                name: "test",
                count: 1,
                price: 1000000,
                permissions: []
            },
            {
                label: "Rifle",
                image: GetItemImage("rifle"),
                name: "rifle",
                count: 1,
                price: 2000000,
                maxCount: 10,
                permissions: ["Rifle Certified"]
            },
            {
                label: "Test",
                image: GetItemImage("test"),
                name: "test",
                count: 1,
                price: 1000000,
                permissions: []
            },
            {
                label: "Rifle",
                image: GetItemImage("rifle"),
                name: "rifle",
                count: 1,
                price: 2000000,
                maxCount: 10,
                permissions: ["Rifle Certified"]
            },
            {
                label: "Test",
                image: GetItemImage("test"),
                name: "test",
                count: 1,
                price: 1000000,
                permissions: []
            },
            {
                label: "Rifle",
                image: GetItemImage("rifle"),
                name: "rifle",
                count: 1,
                price: 2000000,
                maxCount: 10,
                permissions: ["Rifle Certified"]
            },
            {
                label: "Test",
                image: GetItemImage("test"),
                name: "test",
                count: 1,
                price: 1000000,
                permissions: []
            },
            {
                label: "Rifle",
                image: GetItemImage("rifle"),
                name: "rifle",
                count: 1,
                price: 2000000,
                maxCount: 10,
                permissions: ["Rifle Certified"]
            },
            {
                label: "Test",
                image: GetItemImage("test"),
                name: "test",
                count: 1,
                price: 1000000,
                permissions: []
            },
            {
                label: "Rifle",
                image: GetItemImage("rifle"),
                name: "rifle",
                count: 1,
                price: 2000000,
                maxCount: 10,
                permissions: ["Rifle Certified"]
            },
            {
                label: "Test",
                image: GetItemImage("test"),
                name: "test",
                count: 1,
                price: 1000000,
                permissions: []
            },
            {
                label: "Rifle",
                image: GetItemImage("rifle"),
                name: "rifle",
                count: 1,
                price: 2000000,
                maxCount: 10,
                permissions: ["Rifle Certified"]
            },
            {
                label: "Test",
                image: GetItemImage("test"),
                name: "test",
                count: 1,
                price: 1000000,
                permissions: []
            },
            {
                label: "Rifle",
                image: GetItemImage("rifle"),
                name: "rifle",
                count: 1,
                price: 2000000,
                maxCount: 10,
                permissions: ["Rifle Certified"]
            },
            {
                label: "Test",
                image: GetItemImage("test"),
                name: "test",
                count: 1,
                price: 1000000,
                permissions: []
            },
            {
                label: "Rifle",
                image: GetItemImage("rifle"),
                name: "rifle",
                count: 1,
                price: 2000000,
                maxCount: 10,
                permissions: ["Rifle Certified"]
            },
            {
                label: "Test",
                image: GetItemImage("test"),
                name: "test",
                count: 1,
                price: 1000000,
                permissions: []
            },
            {
                label: "Rifle",
                image: GetItemImage("rifle"),
                name: "rifle",
                count: 1,
                price: 2000000,
                maxCount: 10,
                permissions: ["Rifle Certified"]
            },
        ]
    });
    useNuiEvent("updateArmoryInfo", (data: any) => {
        setArmoryInfo(data.armoryInfo);
    });
    return (
        <div className="dark w-screen h-screen absolute text-primary top-0 left-0 bg-gray-900 flex items-center justify-center">
            <Armory armoryInfo={armoryInfo} />
            <AppControls />
        </div>
    )
}