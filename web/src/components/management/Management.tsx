import { Translate, translateText } from "@/providers/locale/Locale"
import { createContext, useContext, useEffect, useState } from "react"
import { Button } from "../ui/button"
import { ArrowLeft, Edit, EyeIcon, Loader2, Plus, Save, Trash, X } from "lucide-react"
import { AppControls } from "@/App"
import { useNuiEvent } from "@/providers/nui/useNui"
import { fetchNui } from "@/providers/nui/fetchNui"
import { useConfig } from "@/providers/config"
import { Department, DepartmentLocation } from "../computer/Computer"
import { Player } from "../computer/RosterPage"
import Table from "../table/Table"

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
                }}>
                    <Plus size={16} />
                    <h2 className="text-md font-bold"><Translate id="create_department" /></h2>
                </div>
                {departments.map((department) => (
                    <div key={department.id} className="p-4 bg-secondary cursor-pointer hover:scale-95 transition-all duration-200" onClick={() => {
                        setCurrentDepartmentId(department.id)
                    }}>
                        <div className="flex flex-row items-center gap-2">
                            <img src={department.image} className="w-8 h-8" style={{display: department.image ? 'block' : 'none'}} />
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

function DropdownSetting({ settingId, value, onUpdate }: { settingId: string, value: string, onUpdate: (value: string) => void }) {
    const { config } = useConfig();
    return (
        <select className="bg-background text-sm text-muted-foreground cursor-pointer transition-all duration-200" value={value} onChange={(e) => onUpdate(e.target.value)}>
            {settingId == "ped" && <option value="">{<Translate id="none" />}</option>}
            {settingId == "ped" && config.peds.map((ped) => (
                <option key={ped.model} value={ped.model}>{ped.label}</option>
            ))}
            {settingId == "garageType" && Object.keys(config.garageTypes).map((garageType) => (
                <option key={garageType} value={garageType}>{config.garageTypes[garageType].label}</option>
            ))}
        </select>
    )
}

function ManagementLocation({ location, onExit, onUpdate, onCreate, onDelete }: { location: DepartmentLocation, onExit: () => void, onUpdate?: (location: DepartmentLocation) => void, onCreate?: (location: DepartmentLocation) => void, onDelete?: () => void }) {
    const { config } = useConfig();
    const { currentDepartmentId } = useManagement();
    const isCreating = location.id === -1;
    const [type, setType] = useState(location.type);
    const locationTypes = config.locationTypes;
    const locationType = locationTypes[type];
    const settingsList = locationType.settings;
    const [settings, setSettings] = useState(location.settings);
    if (!locationType.locations.includes("point")) {
        locationType.locations.unshift("point");
    }
    const [positions, setPositions] = useState(location.positions);
    useEffect(() => {
        if (settingsList.includes("garageType") && (!settings.garageType || !config.garageTypes[settings.garageType])) {
            setSettings({
                ...settings,
                garageType: Object.keys(config.garageTypes)[0],
            })
        }
    }, [settings])
    return (
        <div className="flex flex-col gap-2">
            <hr className="border-b-1 border-primary/50 mt-2"/>
            {isCreating && (
                <div className="flex flex-row gap-2 items-center justify-between w-full">
                    <div className="font-semibold text-md"><Translate id={`location_type`} />:</div>
                    <select className="bg-background text-sm text-muted-foreground cursor-pointer transition-all duration-200" value={type} onChange={(e) => setType(e.target.value)}>
                        {Object.keys(locationTypes).map((locationType) => (
                            <option key={locationType} value={locationType}>{<Translate id={`location_${locationType}`} />}</option>
                        ))}
                    </select>
                </div>
            )}
            {locationTypes[type].locations.map((locationType) => (
                <div className="flex flex-row gap-2 items-center justify-between w-full" key={locationType}>
                    <div className="font-semibold text-md"><Translate id={`location_${locationType}`} />:</div>
                    <Location className="text-muted-foreground text-sm" id={locationType} info={isCreating ? {
                        settings: settings,
                    } : {
                        settings: settings,
                        departmentId: currentDepartmentId,
                        locationId: location.id,
                    }} defaultLocation={positions[locationType] || DEFAULT_LOCATION} onUpdate={(locationData) => {
                        if (!isCreating) {
                            fetchNui("managementAction", {
                                action: "updateLocation",
                                data: {
                                    departmentId: currentDepartmentId,
                                    locationId: location.id,
                                    location: {
                                        ...location,
                                        positions: {
                                            ...positions,
                                            [locationType]: locationData,
                                        },
                                    },
                                },
                            })
                        }
                        else {
                            fetchNui("setCurrentLocation", {
                                departmentId: currentDepartmentId,
                                location: {
                                    id: -1,
                                    type: type,
                                    positions: {
                                        ...positions,
                                        [locationType]: locationData
                                    },
                                    settings: settings,
                                },
                            })
                        }
                        setPositions({
                            ...positions,
                            [locationType]: locationData
                        })
                    }} />
                </div>
            ))}
            {settingsList.map((settingId) => (
                <div className="flex flex-row gap-2 items-center justify-between w-full" key={settingId}>
                    <div className="font-semibold text-md"><Translate id={`setting_${settingId}`} />:</div>
                    {(settingId == "ped" || settingId == "garageType") && <DropdownSetting settingId={settingId} value={settings[settingId]} onUpdate={(value) => {
                        if (!isCreating) {
                            fetchNui("managementAction", {
                                action: "updateLocation",
                                data: {
                                    departmentId: currentDepartmentId,
                                    locationId: location.id,
                                    location: {
                                        ...location,
                                        settings: {
                                            ...settings,
                                            [settingId]: value,
                                        },
                                    },
                                },
                            })
                        }
                        else {
                            fetchNui("setCurrentLocation", {
                                departmentId: currentDepartmentId,
                                location: {
                                    id: -1,
                                    type: type,
                                    positions: positions,
                                    settings: {
                                        ...settings,
                                        [settingId]: value,
                                    },
                                },
                            })
                        }
                        setSettings({ ...settings, [settingId]: value })
                    }} />}
                </div>
            ))}
            {isCreating ? (
                <div onClick={() => onCreate && onCreate({
                    id: -1,
                    type: type,
                    positions: positions,
                    settings: settings,
                })} className="p-2 bg-green-600 cursor-pointer hover:scale-95 transition-all duration-200 flex flex-row items-center justify-center gap-2" key={location.id}>
                    <Save size={16}/>
                    <Translate id="location_create" />
                </div>
            ) : (
                <div onClick={() => onDelete && onDelete()} className="p-2 bg-red-600 cursor-pointer hover:scale-95 transition-all duration-200 flex flex-row items-center justify-center gap-2" key={location.id}>
                    <Trash size={16}/>
                    <Translate id="location_delete" />
                </div>
            )}
        </div>
    )
}

function ManagementDepartment() {
    const { departments, setDepartments, currentDepartmentId, setCurrentDepartmentId, openDialog, closeDialog } = useManagement();
    const creatingDepartment = currentDepartmentId === -1;
    const currentDepartment = departments.find((department) => department.id === currentDepartmentId);
    if (!currentDepartment && !creatingDepartment) return null;
    const { config } = useConfig();
    const [label, setLabel] = useState<string>(creatingDepartment ? translateText(config, "default_department_name", []) : currentDepartment?.label || "");
    const [location, setLocation] = useState<Location>(!currentDepartment ? DEFAULT_LOCATION : currentDepartment.location);
    const [editingLabel, setEditingLabel] = useState(false);
    const [image, setImage] = useState<string>(creatingDepartment ? "" : (currentDepartment?.image || ""));
    const [player, setPlayer] = useState<Player | null>(currentDepartment ? GetDepartmentLeader(currentDepartment) : null);
    const [job, setJob] = useState<string>(creatingDepartment ? Object.keys(config.jobs)[0] : (currentDepartment?.job || ""));
    const [currentLocation, setCurrentLocation] = useState<DepartmentLocation | null>(null);
    const [locations, setLocations] = useState<DepartmentLocation[]>(currentDepartment?.locations || []);
    const [imageLoaded, setImageLoaded] = useState(false);
    const [showBlip, setShowBlip] = useState<boolean>(currentDepartment?.misc?.showBlip !== false);
    useEffect(() => {
        if (!currentDepartment) return;
        setPlayer(GetDepartmentLeader(currentDepartment))
        setLocations(currentDepartment.locations)
        setJob(currentDepartment.job)
        setLocation(currentDepartment.location)
        setShowBlip(currentDepartment.misc?.showBlip !== false)
    }, [departments])
    useEffect(() => {
        fetchNui("setCurrentLocation", {
            departmentId: currentDepartmentId,
            location: currentLocation,
        })
        fetchNui("setHoveredLocation", {
            departmentId: currentDepartmentId,
            locationId: null,
        })
    }, [currentLocation])
    useEffect(() => {
        if (creatingDepartment) return;
        const debouncedSetImage = setTimeout(() => {
            fetchNui("managementAction", {
                action: "updateImage",
                data: {
                    departmentId: currentDepartmentId,
                    image: image,
                },
            })
        }, 500)
        return () => clearTimeout(debouncedSetImage)
    }, [image])
    return (
        <div className="flex flex-col gap-2 select-none">
            <div className="flex flex-row gap-2 items-center justify-between w-full">
                {editingLabel ? (
                    <input className="px-2 pb-2 border-b-2 border-primary bg-background text-2xl cursor-pointer transition-all duration-200" value={label} onChange={(e) => setLabel(e.target.value)} />
                ) : (
                    <div className="px-2 pb-2 font-semibold text-2xl">{label}</div>
                )}
                {editingLabel ? (
                    <Save size={16} className="cursor-pointer hover:scale-95 transition-all duration-200" onClick={() => {
                        fetchNui("managementAction", {
                            action: "updateLabel",
                            data: {
                                departmentId: currentDepartmentId,
                                label: label,
                            },
                        })
                        // setDepartments(departments.map((department) => {
                        //     if (department.id === currentDepartmentId) {
                        //         return {
                        //             ...department,
                        //             label: label
                        //         }
                        //     }
                        //     return department;
                        // }))
                        setEditingLabel(false)
                    }}/>
                ) : (
                    <Edit size={16} className="cursor-pointer hover:scale-95 transition-all duration-200" onClick={() => {
                        setEditingLabel(true)
                    }}/>
                )}
            </div>
            <hr/>
            <div className="flex flex-col gap-2 w-full px-2">
                <div className="flex flex-row gap-2 items-center justify-between w-full">
                    <div className="font-semibold text-md"><Translate id="department_location" />:</div>
                    <Location className="text-muted-foreground text-sm" id="point" info={creatingDepartment ? {
                        settings: {},
                    } : {
                        settings: {},
                        departmentId: currentDepartmentId,
                    }} defaultLocation={location || DEFAULT_LOCATION} onUpdate={(locationData) => {
                        if (creatingDepartment) {
                            setLocation(locationData)
                        }
                        else {
                            fetchNui("managementAction", {
                                action: "updateDepartmentLocation",
                                data: {
                                    departmentId: currentDepartmentId,
                                    location: {
                                        coords: locationData.coords,
                                        rotation: locationData.rotation,
                                    },
                                },
                            })
                        }
                    }} />
                </div>
                <div className="flex flex-row gap-2 items-center justify-between w-full">
                    <div className="font-semibold text-md"><Translate id="department_leader" />:</div>
                    <div className="p-1 px-2 bg-secondary rounded-md cursor-pointer hover:scale-95 transition-all duration-200" onClick={() => {
                        openDialog({
                            title: <Translate id="select_player" />,
                            type: "select_player",
                            onSelect: (newPlayer: Player) => {
                                if (creatingDepartment) {
                                    setPlayer(newPlayer)
                                }
                                else {
                                    fetchNui("managementAction", {
                                        action: "setDepartmentLeader",
                                        data: {
                                            departmentId: currentDepartmentId,
                                            source: newPlayer.source,
                                        }
                                    })
                                }
                                // if (!creatingDepartment && currentDepartment) {
                                //     let members = currentDepartment.members;
                                //     if (members.find((member) => member.identifier === newPlayer.identifier)) { // Is player already a member?
                                //         members = members.map((member) => {
                                //             if (member.identifier === newPlayer.identifier) {
                                //                 return {
                                //                     ...member,
                                //                     rankId: currentDepartment.ranks[0].rankId
                                //                 }
                                //             }
                                //             return member;
                                //         })
                                //     } else {
                                //         members.push({
                                //             identifier: newPlayer.identifier,
                                //             name: newPlayer.name,
                                //             rankId: currentDepartment.ranks[0].rankId,
                                //             recentDutyLogs: [],
                                //             permissions: [],
                                //             onDutyTime: 0,
                                //         })
                                //     }
                                //     if (currentDepartment.ranks.length > 1) { // Demote the current leader, set current leader
                                //         members = members.map((member) => {
                                //             if (member.identifier === player?.identifier) {
                                //                 return {
                                //                     ...member,
                                //                     rankId: currentDepartment.ranks[1].rankId
                                //                 }
                                //             }
                                //             return member;
                                //         })
                                //     } else { // Fire the current leader, set new leader
                                //         members = members.filter((member) => member.identifier !== player?.identifier)
                                //     }
                                //     const updatedDepartments = departments.map((department) => {
                                //         if (department.id === currentDepartmentId) {
                                //             return {
                                //                 ...department,
                                //                 members: members
                                //             }
                                //         }
                                //         return department;
                                //     })
                                //     setDepartments(updatedDepartments)
                                // }
                                closeDialog()
                            }
                        })
                    }}>
                        {player ? player.name : <Translate id="none" />}
                    </div>
                </div>
                <div className="flex flex-row gap-2 items-center justify-between w-full">
                    <div className="font-semibold text-md"><Translate id="department_job" />:</div>
                    <select className="bg-background text-sm text-muted-foreground cursor-pointer transition-all duration-200" value={job} onChange={(e) => {
                        if (creatingDepartment) {
                            setJob(e.target.value)
                        }
                        else {
                            fetchNui("managementAction", {
                                action: "setDepartmentJob",
                                data: {
                                    departmentId: currentDepartmentId,
                                    job: e.target.value,
                                },
                            })
                        }
                    }}>
                        {Object.keys(config.jobs).map((job) => (
                            <option key={job} value={job}>{config.jobs[job].label}</option>
                        ))}
                    </select>
                </div>
                <div className="flex flex-row gap-2 items-center justify-between w-full">
                    <div className="flex flex-row gap-2 items-center">
                        {image != "" && <div className="relative w-8 h-8">
                            {!imageLoaded && (
                                <Loader2 className="w-8 h-8 animate-spin" />
                            )}
                            <img src={image} className="w-8 h-8" onLoad={() => setImageLoaded(true)} style={{display: image ? 'block' : 'none'}} />
                        </div>}
                        <div className="font-semibold text-md"><Translate id="department_image" />:</div>
                    </div>
                    <input type="text" className="bg-background text-sm text-muted-foreground cursor-pointer transition-all duration-200" placeholder="https://example.com/image.png" value={image} onChange={(e) => setImage(e.target.value)} />
                </div>
                {!creatingDepartment && (
                    <div className="flex flex-row gap-2 items-center justify-between w-full">
                        <div className="font-semibold text-md"><Translate id="show_blip" />:</div>
                        <input 
                            type="checkbox" 
                            className="w-4 h-4 cursor-pointer" 
                            checked={showBlip} 
                            onChange={(e) => {
                                const newValue = e.target.checked
                                setShowBlip(newValue)
                                fetchNui("managementAction", {
                                    action: "toggleBlip",
                                    data: {
                                        departmentId: currentDepartmentId,
                                        showBlip: newValue,
                                    },
                                })
                            }} 
                        />
                    </div>
                )}
                {!creatingDepartment && (
                    <>
                        <div className="font-semibold text-md"><Translate id="locations" />:</div>
                        <hr/>
                        <div className="flex flex-col gap-2 overflow-auto max-h-[300px] px-2">
                                <div className="px-4 py-2 bg-secondary font-semibold cursor-pointer hover:scale-95 transition-all duration-200 flex flex-col gap-2" onClick={() => {
                                    if (!currentLocation || currentLocation.id !== -1) {
                                        setCurrentLocation({
                                            id: -1,
                                            type: "front_desk",
                                            positions: {
                                                "point": {
                                                    coords: {
                                                        x: 0,
                                                        y: 0,
                                                        z: 0,
                                                    },
                                                },
                                            },
                                            settings: {},
                                        })
                                    }
                                }}>
                                    <div className="flex flex-row items-center justify-center gap-2">
                                        <Plus size={16} />
                                        <Translate id="create_location" />
                                    </div>
                                        {currentLocation && currentLocation.id === -1 && (
                                            <ManagementLocation 
                                                location={currentLocation} 
                                                onExit={() => setCurrentLocation(null)} 
                                                onUpdate={setCurrentLocation} 
                                                onDelete={() => {
                                                    fetchNui("managementAction", {
                                                        action: "deleteLocation",
                                                        data: {
                                                            departmentId: currentDepartmentId,
                                                            locationId: currentLocation.id,
                                                        },
                                                    })
                                                    setCurrentLocation(null)
                                                }} onCreate={(location: DepartmentLocation) => {
                                                    fetchNui("managementAction", {
                                                        action: "createLocation",
                                                        data: {
                                                            departmentId: currentDepartmentId,
                                                            location: location,
                                                        },
                                                    })
                                                    setTimeout(() => {
                                                        setCurrentLocation(null)
                                                    }, 100)
                                                }} 
                                            />
                                        )}
                                </div>
                                {locations.map((location) => (
                                    <div 
                                        onMouseEnter={() => fetchNui("setHoveredLocation", {
                                            departmentId: currentDepartmentId,
                                            locationId: location.id,
                                        })} 
                                        onMouseLeave={() => fetchNui("setHoveredLocation", {
                                            departmentId: currentDepartmentId,
                                            locationId: null,
                                        })} 
                                        onClick={() => setCurrentLocation(location)} 
                                        className="px-4 py-2 bg-secondary cursor-pointer hover:scale-95 transition-all duration-200 flex flex-col" 
                                        key={location.id}
                                    >
                                        <div className="flex flex-row items-center justify-between">
                                            <Translate id={`location_${location.type}`} />
                                            <div><Translate id="id" args={[location.id]} /></div>
                                        </div>
                                        {currentLocation && currentLocation.id === location.id && (
                                            <ManagementLocation 
                                                location={location} 
                                                onExit={() => setCurrentLocation(null)} 
                                                onUpdate={setCurrentLocation} 
                                                onDelete={() => {
                                                    fetchNui("managementAction", {
                                                        action: "deleteLocation",
                                                        data: {
                                                            departmentId: currentDepartmentId,
                                                            locationId: location.id,
                                                        },
                                                    })
                                                    // setLocations(locations.filter((targetLocation) => location.id !== targetLocation.id))
                                                    // if (location.id === -1) return;
                                                    // setDepartments(departments.map((department) => {
                                                    //     if (department.id === currentDepartmentId) {
                                                    //         return {
                                                    //             ...department,
                                                    //             locations: department.locations.filter((targetLocation) => location.id !== targetLocation.id)
                                                    //         }
                                                    //     }
                                                    //     return department;
                                                    // }))
                                                    setCurrentLocation(null)
                                                }} onCreate={(location: DepartmentLocation) => {
                                                    fetchNui("managementAction", {
                                                        action: "createLocation",
                                                        data: {
                                                            departmentId: currentDepartmentId,
                                                            location: location,
                                                        },
                                                    })
                                                    // let newLocationId = 1;
                                                    // for (const location of locations) {
                                                    //     if (location.id >= newLocationId) {
                                                    //         newLocationId = location.id + 1;
                                                    //     }
                                                    // }
                                                    // setLocations([...locations, {
                                                    //     id: newLocationId,
                                                    //     type: location.type,
                                                    //     positions: location.positions,
                                                    // }])
                                                    // if (!creatingDepartment) {
                                                    //     setDepartments(departments.map((department) => {
                                                    //         if (department.id === currentDepartmentId) {
                                                    //             return {
                                                    //                 ...department,
                                                    //                 locations: [...department.locations]
                                                    //             }
                                                    //         }
                                                    //         return department;
                                                    //     }))
                                                    // }
                                                    setCurrentLocation(null)
                                                }} 
                                            />
                                        )}
                                    </div>
                                ))}
                        </div>
                        <div className="font-semibold text-md"><Translate id="roster" />:</div>
                        <hr/>
                        <div className="flex flex-col gap-2 overflow-auto max-h-[300px] px-2">
                            <div className="px-4 py-2 bg-secondary font-semibold cursor-pointer hover:scale-95 transition-all duration-200 flex flex-row items-center justify-center gap-2" onClick={() => {
                                openDialog({
                                    title: <Translate id="add_member" />,
                                    type: "select_player",
                                    onSelect: (newPlayer: Player) => {
                                        fetchNui("managementAction", {
                                            action: "hireMember",
                                            data: {
                                                departmentId: currentDepartmentId,
                                                source: newPlayer.source,
                                            }
                                        })
                                        closeDialog()
                                    }
                                })
                            }}>
                                <Plus size={16} />
                                <Translate id="add_member" />
                            </div>
                            {currentDepartment && currentDepartment.members
                                .filter((member) => {
                                    // Exclude the leader (member with rankId matching the first rank)
                                    const leaderRankId = currentDepartment.ranks[0]?.rankId
                                    return member.rankId !== leaderRankId
                                })
                                .map((member) => {
                                    const rank = currentDepartment.ranks.find((r) => r.rankId === member.rankId)
                                    return (
                                        <div key={member.identifier} className="px-4 py-2 bg-secondary cursor-pointer hover:scale-95 transition-all duration-200 flex flex-row items-center justify-between">
                                            <div className="flex flex-col">
                                                <div className="font-semibold">{member.name}</div>
                                                <div className="text-sm text-muted-foreground">{rank?.label || "Unknown Rank"}</div>
                                            </div>
                                            <Button variant="outline" size="icon" onClick={(e) => {
                                                e.stopPropagation()
                                                openDialog({
                                                    title: <Translate id="fire_member" />,
                                                    type: "delete_department",
                                                    onConfirm: () => {
                                                        fetchNui("managementAction", {
                                                            action: "fireMember",
                                                            data: {
                                                                departmentId: currentDepartmentId,
                                                                identifier: member.identifier,
                                                            }
                                                        })
                                                        closeDialog()
                                                    }
                                                })
                                            }}>
                                                <Trash size={16} className="text-red-500" />
                                            </Button>
                                        </div>
                                    )
                                })}
                        </div>
                    </>
                )}
            </div>
            <hr/>
            <div className="px-2 flex flex-col gap-2">
                {creatingDepartment ? (
                    <div className="p-4 bg-green-600 cursor-pointer hover:scale-95 transition-all duration-200 flex flex-row items-center justify-center gap-2" onClick={() => {
                        setCurrentDepartmentId(null)
                        fetchNui("managementAction", {
                            action: "createDepartment",
                            data: {
                                label: label,
                                image: image,
                                leader: player ? player.source : null,
                                job: job,
                            },
                        })
                        // setDepartments([...departments, {
                        //     id: departments.length + 1,
                        //     label: label,
                        //     members: player ? [
                        //         {
                        //             identifier: player?.identifier || "",
                        //             name: player?.name || "",
                        //             rankId: 1,
                        //             recentDutyLogs: [],
                        //             permissions: [],
                        //             onDutyTime: 0,
                        //         }
                        //     ] : [],
                        //     locations: locations,
                        //     ranks: [
                        //         {
                        //             rankId: 1,
                        //             label: translateText(config, "default_rank_name", []),
                        //             managingRankIds: [],
                        //             armory: [],
                        //             vehicles: [],
                        //         }
                        //     ],
                        //     permissions: {},
                        // }])
                    }}>
                        <Save size={16} />
                        <h2 className="text-md font-bold"><Translate id="create_department" /></h2>
                    </div>
                ) : (
                    <div className="p-4 bg-red-600 cursor-pointer hover:scale-95 transition-all duration-200 flex flex-row items-center justify-center gap-2" onClick={() => {
                        openDialog({
                            title: <Translate id="delete_department" />,
                            type: "delete_department",
                            onConfirm: () => {
                                fetchNui("managementAction", {
                                    action: "deleteDepartment",
                                    data: {
                                        departmentId: currentDepartmentId,
                                    },
                                })
                                // setDepartments(departments.filter((department) => department.id !== currentDepartmentId))
                                setCurrentDepartmentId(null)
                                closeDialog()
                            }
                        })
                    }}>
                        <Trash size={16} />
                        <h2 className="text-md font-bold"><Translate id="delete_department" /></h2>
                    </div>
                )}
                <div className="p-4 bg-secondary cursor-pointer hover:scale-95 transition-all duration-200 flex flex-row items-center justify-center gap-2" onClick={() => {
                    setCurrentDepartmentId(null)
                    fetchNui("setCurrentLocation", {
                        location: null,
                    })
                    fetchNui("setHoveredLocation", {
                        departmentId: currentDepartmentId,
                        locationId: null,
                    })
                }}>
                    <ArrowLeft size={16} />
                    <h2 className="text-md font-bold"><Translate id="return_to_departments" /></h2>
                </div>
            </div>
        </div>
    )
}

function SelectPlayerDialog({onSelect}: {onSelect: (player: Player) => void}) {
    const [players, setPlayers] = useState<Player[]>([])
    useEffect(() => {
        fetchNui("getPlayers", {}).then((data: any) => {
            setPlayers(data.players)
        }).catch((error: any) => {
            setPlayers([])
        })
    }, [])
    return (
        <div className="flex flex-col gap-2 overflow-auto">
            <div className="font-semibold text-md"><Translate id="select_player" />: </div>
            <Table maxHeight="100%" defaultSortKey="source" data={players.map((player) => ({
                ...player,
                source: player.source?.toString() || "Unknown",
                action: (<div className="flex items-center gap-2 justify-end">
                    <Button variant="outline" size="icon" onClick={() => {
                        onSelect(player)                        
                    }}>
                        <Plus size={16} />
                    </Button>
                </div>)
            }))} columns={[
                {
                    key: "source",
                    header: "Source",
                },
                {
                    key: "name",
                    header: "Name",
                },
                {
                    key: "action",
                    header: "",
                },
            ]} />
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
    useNuiEvent("updateManagement", (rawdata: any) => {
        const data = rawdata.data;
        if (data.type === "updateMembers") {
            setDepartments(departments.map((department) => {
                if (department.id === data.departmentId) {
                    return {
                        ...department,
                        members: data.members,
                    }
                }
                return department;
            }))
        } else if (data.type === "createDepartment") {
            setDepartments([...departments, data.department])
        } else if (data.type === "deleteDepartment") {
            setDepartments(departments.filter((department) => department.id !== data.departmentId))
        } else if (data.type === "createLocation") {
            setDepartments(departments.map((department) => {
                if (department.id === data.departmentId) {
                    return {
                        ...department,
                        locations: [...department.locations, data.location]
                    }
                }
                return department;
            }))
        } else if (data.type === "updateLocation") {
            setDepartments(departments.map((department) => {
                if (department.id === data.departmentId) {
                    return {
                        ...department,
                        locations: department.locations.map((location) => location.id === data.locationId ? data.location : location)
                    }
                }
                return department;
            }))
        } else if (data.type === "deleteLocation") {
            setDepartments(departments.map((department) => {
                if (department.id === data.departmentId) {
                    return {
                        ...department,
                        locations: department.locations.filter((location) => location.id !== data.locationId)
                    }
                }
                return department;
            }))
        } else if (data.type === "setDepartmentJob") {
            setDepartments(departments.map((department) => {
                if (department.id === data.departmentId) {
                    return {
                        ...department,
                        job: data.job,
                    }
                }
                return department;
            }))
        } else if (data.type === "updateLabel") {
            setDepartments(departments.map((department) => {
                if (department.id === data.departmentId) {
                    return {
                        ...department,
                        label: data.label,
                    }
                }
                return department;
            }))
        } else if (data.type === "updateImage") {
            setDepartments(departments.map((department) => {
                if (department.id === data.departmentId) {
                    return {
                        ...department,
                        image: data.image,
                    }
                }
                return department;
            }))
        } else if (data.type === "updateDepartmentLocation") {
            setDepartments(departments.map((department) => {
                if (department.id === data.departmentId) {
                    return {
                        ...department,
                        location: data.location,
                    }
                }
                return department;
            }))
        } else if (data.type === "toggleBlip") {
            setDepartments(departments.map((department) => {
                if (department.id === data.departmentId) {
                    return {
                        ...department,
                        misc: {
                            ...department.misc,
                            showBlip: data.showBlip,
                        },
                    }
                }
                return department;
            }))
        } else {
            console.log("Unknown updateManagement type", JSON.stringify(data, null, 2))
        }
    })
    // useNuiEvent("updateManagementMembers", (data: any) => {
    //     setDepartments(departments.map((department) => {
    //         if (department.id === data.departmentId) {
    //             return {
    //                 ...department,
    //                 members: data.members,
    //             }
    //         }
    //         return department;
    //     }))
    // })
    // useNuiEvent("createManagementDepartment", (data: any) => {
    //     setDepartments([...departments, data.department])
    // })
    return (
        <ManagementContext.Provider value={value}>
            <div className="flex flex-col gap-2 select-none">
                {dialog && (
                    <div className="z-10 absolute top-0 left-0 w-full h-full flex items-center justify-center bg-black/50 transition-opacity duration-300" style={{opacity: dialogVisible ? 1 : 0}}>
                        <div className="bg-background w-[calc(100%-20px)]">
                            <div className="relative w-full h-[50px] bg-secondary flex items-center justify-center">
                                <div className="font-semibold text-md">{dialog.title}</div>
                                <div className="absolute right-0 top-0 w-[50px] h-[50px] flex items-center cursor-pointer justify-center bg-red-600 hover:bg-red-700 transition-all duration-200" onClick={closeDialog}>
                                    <X size={20} className="cursor-pointer hover:scale-95 transition-all duration-200"/>
                                </div>
                            </div>
                            <div className="flex flex-col gap-0 p-2 max-h-[300px]">
                                {dialog.type === "select_player" && (
                                    <SelectPlayerDialog onSelect={dialog.onSelect} />
                                )}
                                {dialog.type === "delete_department" && (
                                    <div className="flex flex-col gap-2">
                                        <div className="font-semibold text-md"><Translate id="delete_department_confirm" /></div>
                                        <div className="flex flex-row gap-2 justify-end">
                                            <Button className="px-8" variant="outline" size="icon" onClick={dialog.onConfirm}>
                                               <Translate id="yes" />
                                            </Button>
                                        </div>
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
    const [visible, setVisible] = useState(false)
    const [departments, setDepartments] = useState<Department[]>([])
    const [focus, setFocus] = useState(false)
    const [hidden, setHidden] = useState(true)
    useNuiEvent("setManagementHidden", (data: any) => {
        setHidden(data.hidden)
    });
    useEffect(() => {
        const handleKeyDown = (event: KeyboardEvent) => {
            if (event.target instanceof HTMLInputElement || event.target instanceof HTMLTextAreaElement) return;
            if (!visible) return;
            if (event.key === "Escape" || event.key === "Backspace") {
                fetchNui("exitManagementEditor", {});
            }
            if (event.key === "g") {
                fetchNui("disableManagementFocus", {});
            }
        };

        window.addEventListener("keydown", handleKeyDown);

        return () => {
            window.removeEventListener("keydown", handleKeyDown);
        };
    });
    useNuiEvent("setManagementFocus", (data: any) => {
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
    useNuiEvent("closeManagementEditor", () => {
        setHidden(true)
        setFocus(false)
        setTimeout(() => {
            setVisible(false)
        }, 300)
    });
    return visible &&(
        <div className="dark w-screen h-screen absolute text-primary top-0 left-0 flex items-center justify-center">
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