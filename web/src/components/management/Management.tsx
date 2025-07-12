import { Translate } from "@/providers/locale/Locale"
import { createContext, useContext, useEffect, useState } from "react"
import { Button } from "../ui/button"
import { ArrowLeft, Edit, Plus, Save } from "lucide-react"
import { AppControls } from "@/App"
import { useNuiEvent } from "@/providers/nui/useNui"
import { fetchNui } from "@/providers/nui/fetchNui"
import { useConfig } from "@/providers/config"
import { Department } from "../computer/Computer"
import { Player } from "../computer/RosterPage"

const DEFAULT_LOCATION: Location = {
    coords: {x: 0, y: 0, z: 0},
    rotation: {x: 0, y: 0, z: 0},
}

type vector3 = {
    x: number,
    y: number,
    z: number,
}

export type Location = {
    coords: vector3,
    rotation?: vector3,
}


function Location({ id, info, defaultLocation, className, onUpdate }: { id?: any, info?: any, defaultLocation: Location, className?: string, onUpdate?: (location: Location) => void }) {
    const coordinates = defaultLocation.coords || {x: 0, y: 0, z: 0}
    const rotation = defaultLocation.rotation || {x: 0, y: 0, z: 0}
    useNuiEvent("setLocation", (data: any) => {
        if (!id && data.id) return;
        if (id && data.id !== id) return;
        if (onUpdate) {
            onUpdate(data.location)
        }
    })
    return (
        <div className="flex flex-row items-center gap-2">
            <div className={className}>{`vector3(${coordinates.x.toFixed(2)}, ${coordinates.y.toFixed(2)}, ${coordinates.z.toFixed(2)})`}</div>
            {onUpdate && (
                <Edit size={16} className="cursor-pointer hover:scale-95 transition-all duration-200" onClick={() => {
                    fetchNui("editLocation", {
                        id: id,
                        info: info,
                        coords: coordinates, 
                        rotation: rotation,
                    })
                    // Do cool stuff here
                }}/>
            )}
        </div>
    )
}

interface ManagementContextProps {
    departments: Department[];
    setDepartments: (departments: Department[]) => void;
    currentDepartmentId: number | null;
    setCurrentDepartmentId: (departmentId: number | null) => void;
    openDialog: (dialog: any) => void;
    closeDialog: () => void;
}

const ManagementContext = createContext<ManagementContextProps | undefined>(undefined);

function ManagementDepartmentList() {
    const { departments, setCurrentDepartmentId } = useManagement();
    return (
        <div className="flex flex-col gap-2">
            <div  className="px-2 pb-2 font-semibold text-2xl"><Translate id="departments" /></div>
            <hr className="mb-2"/>
            <div className="flex flex-col gap-2 overflow-auto max-h-[950px] px-2">
                <div className="p-4 bg-secondary cursor-pointer hover:scale-95 transition-all duration-200 flex flex-row items-center justify-center gap-2" onClick={() => {
                    setCurrentDepartmentId(-1)
                    fetchNui("createDepartment", {})
                }}>
                    <Plus size={16} />
                    <h2 className="text-md font-bold"><Translate id="create_department" /></h2>
                </div>
                {departments.map((department) => (
                    <div key={department.id} className="p-4 bg-secondary cursor-pointer hover:scale-95 transition-all duration-200" onClick={() => {
                        setCurrentDepartmentId(department.id)
                    }}>
                        <div className="flex flex-row items-center justify-between">
                            <h2 className="text-md font-bold">{department.label}</h2>
                        </div>
                    </div>
                ))}
            </div>
        </div>
    )
}

function GetDepartmentLeader(department: Department): Player | null {
    const leader = department.members.find((member) => member.rankId === department.ranks[0].rankId) ?? null;
    if (!leader) return null;
    return {
        name: leader.name,
        identifier: leader.identifier,
    }
}

function ManagementDepartment() {
    const { departments, currentDepartmentId, setCurrentDepartmentId, openDialog } = useManagement();
    const creatingDepartment = currentDepartmentId === -1;
    const currentDepartment = departments.find((department) => department.id === currentDepartmentId);
    if (!currentDepartment && !creatingDepartment) return null;
    const [label, setLabel] = useState(creatingDepartment ? "New Department" : currentDepartment?.label);
    const [player, setPlayer] = useState<Player | null>(currentDepartment ? GetDepartmentLeader(currentDepartment) : null);
    return (
        <div className="flex flex-col gap-2">
            <div className="px-2 pb-2 font-semibold text-2xl">{label}</div>
            <hr/>
            <div className="flex flex-row gap-2 w-full">
                <div className="flex flex-row gap-2 items-center justify-between w-full">
                    <div className="font-semibold text-md"><Translate id="department_leader" />:</div>
                    <div className="p-1 px-2 bg-secondary rounded-md cursor-pointer hover:scale-95 transition-all duration-200" onClick={() => {
                        openDialog({
                            type: "select_player",
                            onSelect: (player: Player) => {
                                setPlayer(player)
                            }
                        })
                    }}>
                        {player ? player.name : <Translate id="none" />}
                    </div>
                </div>
            </div>
            <div className="p-4 bg-secondary cursor-pointer hover:scale-95 transition-all duration-200 flex flex-row items-center justify-center gap-2" onClick={() => {
                setCurrentDepartmentId(null)
            }}>
                <ArrowLeft size={16} />
                <h2 className="text-md font-bold"><Translate id="return_to_departments" /></h2>
            </div>
        </div>
    )
}
function Management({ defaultDepartments }: { defaultDepartments: Department[] }) {
    const {config} = useConfig()
    const [departments, setDepartments] = useState<Department[]>(defaultDepartments)
    const [currentDepartmentId, setCurrentDepartmentId] = useState<number | null>(null);
    const [dialogVisible, setDialogVisible] = useState(false);
    const [dialog, setDialog] = useState<any>(null);
    const openDialog = (dialog: any) => {
        setDialog(dialog)
        setTimeout(() => {
            setDialogVisible(true)
        }, 10)
    }
    const closeDialog = () => {
        setDialogVisible(false)
        setTimeout(() => {
            setDialog(null)
        }, 300)
    }
    const value = {
        departments,
        setDepartments,
        currentDepartmentId,
        setCurrentDepartmentId,
        openDialog,
        closeDialog,
    }
    return (
        <ManagementContext.Provider value={value}>
            <div className="flex flex-col gap-2">
                {dialog && (
                    <div className="absolute top-0 left-0 w-full h-full flex items-center justify-center bg-black/50 transition-opacity duration-300" style={{opacity: dialogVisible ? 1 : 0}}>
                        <div className="bg-background p-4 w-[calc(100%-20px)]">
                            <div className="flex flex-col gap-0">
                                <div className="w-full h-[50px] bg-secondary flex items-center justify-center">
                                    <div className="font-semibold text-md">{dialog.title}</div>
                                </div>
                                {dialog.type === "select_player" && (
                                    <div className="flex flex-col gap-2">
                                        balls
                                    </div>
                                )}
                            </div>
                        </div>
                    </div>
                )}
                {currentDepartmentId !== null ? (
                    <ManagementDepartment />
                ) : (
                    <ManagementDepartmentList />
                )}
                <div className="position absolute bottom-0 left-[50%] translate-x-[-50%] w-full h-[50px] bg-secondary/50 flex items-center justify-center gap-2">
                    <div className="font-semibold">&copy; Pickle Mods</div>
                </div>
            </div>
        </ManagementContext.Provider>
    )
}

function useManagement(): ManagementContextProps {
    const context = useContext(ManagementContext)
    if (!context) {
        throw new Error("useManagement must be used within a ManagementProvider")
    }
    return context
}

export default function ManagementDisplay() {
    const [visible, setVisible] = useState(true)
    const [departments, setDepartments] = useState<Department[]>([
        {
            id: 11,
            label: "Los Santos Police Department",
            ranks: [
                {
                    "rankId":1,
                    "label":"Chief", 
                    "managingRankIds":[],
                    "armory": [],
                    "vehicles": [],
                },
                {
                    "rankId":2,
                    "label":"Lieutenant", 
                    "managingRankIds":[],
                    "armory": [],
                    "vehicles": [],
                },
                {
                    "rankId":3,
                    "label":"Sergeant",
                    "managingRankIds":[2],
                    "armory": [],
                    "vehicles": [],
                },
                {
                    "rankId":4,
                    "label":"Officer",
                    "managingRankIds":[1,2,3],
                    "armory": [],
                    "vehicles": [],
                },
                {
                    "rankId":5,
                    "label":"Recruit",
                    "managingRankIds":[1,2,3],
                    "armory": [],
                    "vehicles": [],
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
        }
    ])
    const [focus, setFocus] = useState(true)
    const [hidden, setHidden] = useState(false)
    useNuiEvent("setEditorHidden", (data: any) => {
        setHidden(data.hidden)
    });
    useEffect(() => {
        const handleKeyDown = (event: KeyboardEvent) => {
            if (event.target instanceof HTMLInputElement || event.target instanceof HTMLTextAreaElement) return;
            if (!visible) return;
            if (event.key === "Escape" || event.key === "Backspace") {
                fetchNui("exitCasinoEditor", {});
            }
            if (event.key === "g") {
                fetchNui("disableEditorFocus", {});
            }
        };

        window.addEventListener("keydown", handleKeyDown);

        return () => {
            window.removeEventListener("keydown", handleKeyDown);
        };
    });
    useNuiEvent("setEditorFocus", (data: any) => {
        setFocus(data.toggle)
    });
    useNuiEvent("openManagementEditor", (data: any) => {
        setDepartments(data.departments)
        setHidden(true)
        setVisible(true)
        setTimeout(() => {
            setHidden(false)
        }, 50)
    });
    useNuiEvent("closeCasinoEditor", () => {
        setHidden(true)
        setFocus(false)
        setTimeout(() => {
            setVisible(false)
        }, 300)
    });
    return (
        <div className="dark w-screen h-screen absolute text-primary top-0 left-0 bg-gray-900 flex items-center justify-center">
            {(visible && !hidden) && <AppControls controls={[{key: "G", label: <Translate id={"focus_" + (focus ? "off" :  "on")}/>}]} />}
            {visible && (
                <div className="absolute top-0 left-0 w-full h-full overflow-hidden">
                    <div
                        className={`relative ml-auto px-2 py-2 w-[400px] h-full bg-background/95 transition-transform duration-300 ${
                        hidden ? "translate-x-full" : "translate-x-0"
                        }`}
                    > 
                    <Management defaultDepartments={departments} />
                    </div>
                </div>  
            )}
        </div>
    )
}