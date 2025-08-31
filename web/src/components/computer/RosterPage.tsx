import { useNuiEvent } from "@/providers/nui/useNui";
import { useContext, useEffect, useState } from "react";
import Table from "../table/Table";
import { Translate, translateText } from "@/providers/locale/Locale";
import { Button } from "../ui/button";
import { ArrowDown, ArrowUp, Check, CheckIcon, DoorOpen, Edit, EyeIcon, InfoIcon, LogOut, Pencil, PlusIcon, SaveIcon, Trash, X } from "lucide-react";
import ComputerContext, { useComputer } from "./Computer";
import { ItemDisplay } from "../armory/Armory";
import { useConfig } from "@/providers/config";
import { fetchNui } from "@/providers/nui/fetchNui";

type DutyLog = {
    duration: number;
    finishTimestamp: string;
    startTimestamp: string;
    finish: number;
    report?: string;
}

export type DepartmentMember = {
    identifier: string;
    name: string;
    rankId: number;
    recentDutyLogs: DutyLog[];
    permissions: string[];
    onDuty?: number;
    onDutyTime: number;
}

export type DepartmentRank = {
    rankId: number;
    label: string;
    managingRankIds: number[];
}

export function GetStopwatchTime(time: number) {
    const weeks = Math.floor(time / (7 * 24 * 3600));
    const days = Math.floor((time % (7 * 24 * 3600)) / (24 * 3600));
    const hours = Math.floor((time % (24 * 3600)) / 3600);
    const minutes = Math.floor((time % 3600) / 60);
    const seconds = time % 60;

    const timeUnits = [
        { value: weeks, unit: weeks > 1 ? "weeks" : "week" },
        { value: days, unit: days > 1 ? "days" : "day" },
        { value: hours, unit: hours > 1 ? "hours" : "hour" },
        { value: minutes, unit: minutes > 1 ? "minutes" : "minute" },
        { value: seconds, unit: seconds > 1 ? "seconds" : "second" }
    ];

    const nonZeroUnits = timeUnits.filter(unit => unit.value > 0);
    const topTwoUnits = nonZeroUnits.slice(0, 2);
    if (time === 0) {
        return (
            <span>
                0 <Translate id="seconds" />
            </span>
        );
    }

    return (
        <span>
            {topTwoUnits.map((unit, index) => (
                <span key={unit.unit}>
                    {unit.value.toString()} <Translate id={unit.unit} />
                    {index < topTwoUnits.length - 1 && ' and '}
                </span>
            ))}
        </span>
    )
}

export function CanRankManageRank(managingRankId: number, rankId: number) {
    const { department } = useComputer();
    if (rankId === managingRankId) return false;
    const rank = department.ranks.find((rank) => rank.rankId === rankId);
    if (!rank) return false;
    if (department.ranks[0].rankId === managingRankId) {
        return true;
    }
    if (!rank.managingRankIds.includes(managingRankId)) {
        return false;
    }
    for (let i = 0; i < department.ranks.length; i++) {
        if (department.ranks[i].rankId === managingRankId) {
            break;
        }
        if (department.ranks[i].rankId === rankId) {
            return false;
        }
    }
    return true;
}

export function CanRankManagePermission(managingRankId: number, permission: string) {
    const { department } = useComputer();
    if (department.ranks[0].rankId === managingRankId) {
        return true;
    }
    return department.permissions[permission].managingRankIds.includes(managingRankId);
}

export type Player = {
    name: string;
    source?: number;
    identifier: string;
}

function SelectedMemberModal({memberIdentifier, onClose, isModalVisible}: {memberIdentifier: string, onClose: () => void, isModalVisible: boolean}) {
    const { department, player, setDepartment, openWindow } = useComputer();
    const [isAddingPermission, setIsAddingPermission] = useState(false);
    const [selectedPermission, setSelectedPermission] = useState("");
    const [isFiringMember, setIsFiringMember] = useState(false);
    const member = department.members.find((m) => m.identifier === memberIdentifier);
    if (!member) return null;
    let memberRank = department.ranks.find((r) => r.rankId === member.rankId);
    if (!memberRank) return null;
    let memberPermissions = [];
    for (let i = 0; i < Object.keys(department.permissions).length; i++) {
        if (member?.permissions.includes(Object.keys(department.permissions)[i])) {
            memberPermissions.push(Object.keys(department.permissions)[i]);
        }
    }
    if (!member) return null;
    return (
        <div className={`absolute inset-0 bg-background/50 backdrop-blur-sm z-[50] flex items-center justify-center transition-opacity duration-200 ${isModalVisible ? 'opacity-100' : 'opacity-0'}`}>
            <div className={`bg-background/95 w-[75%] h-[75%] shadow-lg transition-all duration-200 ${isModalVisible ? 'scale-100 opacity-100' : 'scale-95 opacity-0'}`}>
                <div className="relative w-full h-[30px] bg-secondary flex items-center justify-between select-none ">
                    <div className="flex items-center justify-center gap-2 pl-2">
                        <div className="font-semibold text-sm text-white">{member.name}</div>
                    </div>
                    <div className="flex items-center justify-center gap-2 hover:bg-destructive/50 transition-all duration-300 h-[30px] w-[30px] cursor-pointer" onClick={onClose}>
                        <X/>
                    </div>
                </div>
                <div className="w-full h-[calc(100%-30px)] p-2 overflow-y-auto">
                    <div className="flex flex-col gap-2">
                        <div className="flex flex-row items-center gap-4">
                            <div className="flex flex-col items-center gap-2">
                                <img src={`https://ui-avatars.com/api/?name=${encodeURIComponent(member.name)}&background=random&color=fff&size=128`} alt={member.name} className="w-20 h-20 rounded-full" draggable={false}/>
                                <div className="flex flex-col items-center gap-2">
                                    <h2 className="text-lg font-bold text-primary whitespace-nowrap">{member.name}</h2>
                                    {CanRankManageRank(player.rankId, member.rankId) && (
                                        <div className="w-full whitespace-nowrap flex items-center justify-center gap-2 bg-destructive hover:bg-destructive/80 transition-colors duration-200 cursor-pointer rounded-md p-1 font-semibold text-xs text-center" onClick={() => {
                                            if (isFiringMember) {
                                                setIsFiringMember(false);
                                                fetchNui("updateComputerDepartment", {
                                                    type: "removeMember",
                                                    identifier: member.identifier,
                                                });
                                                // setDepartment({
                                                //     ...department,
                                                //     members: department.members.filter(m => m.identifier !== member.identifier),
                                                // });
                                                onClose();
                                            } else {
                                                setIsFiringMember(true);
                                            }
                                        }}>
                                            <LogOut className="w-3 h-3" />
                                            {isFiringMember ? (
                                                <Translate id="confirm_fire_member" />
                                            ) : (
                                                <Translate id="fire_member" />
                                            )}
                                        </div>
                                    )}
                                    {/* <p className="text-muted-foreground whitespace-nowrap">{department.ranks.find((rank) => rank.rankId === member.rankId)?.label || "Unknown"}</p> */}
                                </div>
                            </div>
                            <div className="flex flex-col gap-2 relative">
                                <div className="text-xl font-bold text-primary"><Translate id="info" /></div>
                                <div className="flex flex-col gap-2">
                                    <div className="flex flex-row gap-2 ">
                                        <div className="text-sm font-semibold"><Translate id="total_on_duty" />:</div>
                                        <div className="text-sm text-muted-foreground">{GetStopwatchTime(member.onDutyTime)}</div>
                                    </div>
                                    <div className="flex flex-row gap-2">
                                        <div className="text-sm font-semibold"><Translate id="last_shift" />:</div>
                                        <div className="text-sm text-muted-foreground">{member.recentDutyLogs.length > 0 ? new Date((member.recentDutyLogs[0].finish - member.recentDutyLogs[0].duration) * 1000).toLocaleString() : "Never"}</div>
                                    </div>
                                    <div className="flex flex-row gap-2 items-center">
                                        <div className="text-sm font-semibold"><Translate id="rank" />:</div>
                                        {CanRankManageRank(player.rankId, member.rankId) ? (
                                        <select className="w-full bg-background text-sm p-1 rounded border border-border" value={member.rankId} onChange={(e) => {
                                            fetchNui("updateComputerDepartment", {
                                                type: "updateMemberRank",
                                                identifier: member.identifier,
                                                rankId: parseInt(e.target.value),
                                            });
                                            // setDepartment({
                                            //     ...department,
                                            //     members: department.members.map(m => m.identifier === member.identifier ? { ...m, rankId: parseInt(e.target.value) } : m),
                                            // });
                                        }}>
                                            <option key={member.rankId} value={member.rankId}>{department.ranks.find((rank) => rank.rankId === member.rankId)?.label || "Unknown"}</option>
                                            {department.ranks.map((rank) => (rank.rankId !== member.rankId && CanRankManageRank(player.rankId, rank.rankId)) && (
                                                <option key={rank.rankId} value={rank.rankId}>{rank.label}</option>
                                            ))}
                                            </select>
                                        ) : (
                                            <div className="text-sm text-muted-foreground">{department.ranks.find((rank) => rank.rankId === member.rankId)?.label || "Unknown"}</div>
                                        )}
                                    </div>
                                    <div className="flex flex-row gap-2">
                                        <div className="grid grid-cols-3 gap-2 select-none">
                                            {memberPermissions.map((permission) => (
                                                <div key={permission} className="relative">
                                                    <div className="bg-secondary relative rounded-md p-1 font-semibold text-xs text-center">
                                                        {permission}
                                                        {(CanRankManageRank(player.rankId, member.rankId) && CanRankManagePermission(player.rankId, permission)) && (
                                                            <div className="absolute inset-0 bg-destructive/95 rounded-md flex items-center justify-center opacity-0 hover:opacity-100 transition-opacity duration-200 cursor-pointer" onClick={() => {
                                                                fetchNui("updateComputerDepartment", {
                                                                    type: "deleteMemberPermission",
                                                                    identifier: member.identifier,
                                                                    label: permission,
                                                                });
                                                                // setDepartment({
                                                                //     ...department,
                                                                //     members: department.members.map(m => m.identifier === member.identifier ? { ...m, permissions: m.permissions.filter(p => p !== permission) } : m),
                                                                // });
                                                            }}>
                                                                <X className="w-4 h-4 text-white" />
                                                            </div>
                                                        )}
                                                    </div>
                                                </div>
                                            ))}
                                            {CanRankManageRank(player.rankId, member.rankId) && (
                                            isAddingPermission ? (
                                                <div className="bg-secondary rounded-md p-1">
                                                    <select 
                                                        className="w-full bg-background text-xs p-1 rounded border border-border"
                                                        value={selectedPermission}
                                                        onChange={(e) => setSelectedPermission(e.target.value)}
                                                    >
                                                        <option value="">Select permission...</option>
                                                        {Object.keys(department.permissions)
                                                            .filter(permission => !member.permissions.includes(permission) && CanRankManagePermission(player.rankId, permission))
                                                            .map(permission => (
                                                                <option key={permission} value={permission}>
                                                                    {permission}
                                                                </option>
                                                            ))
                                                        }
                                                    </select>
                                                    <div className="flex gap-1 mt-2">
                                                        <button 
                                                            className="flex-1 bg-green-600 hover:bg-green-700 text-white text-xs p-1 rounded flex items-center justify-center gap-1"
                                                            onClick={() => {
                                                                if (selectedPermission) {
                                                                    fetchNui("updateComputerDepartment", {
                                                                        type: "addMemberPermission",
                                                                        identifier: member.identifier,
                                                                        label: selectedPermission,
                                                                    });
                                                                    // setDepartment({
                                                                    //     ...department,
                                                                    //     members: department.members.map(m => 
                                                                    //         m.identifier === member.identifier 
                                                                    //             ? { ...m, permissions: [...m.permissions, selectedPermission] }
                                                                    //             : m
                                                                    //     )
                                                                    // });
                                                                    setSelectedPermission("");
                                                                    setIsAddingPermission(false);
                                                                }
                                                            }}
                                                        >
                                                            <Check className="w-3 h-3" />
                                                            Save
                                                        </button>
                                                        <button 
                                                            className="flex-1 bg-gray-600 hover:bg-gray-700 text-white text-xs p-1 rounded flex items-center justify-center gap-1"
                                                            onClick={() => {
                                                                setSelectedPermission("");
                                                                setIsAddingPermission(false);
                                                            }}
                                                        >
                                                            <X className="w-3 h-3" />
                                                            Cancel
                                                        </button>
                                                    </div>
                                                </div>
                                            ) : (
                                                <div 
                                                    className="bg-secondary rounded-md p-1 font-semibold text-xs flex items-center justify-center gap-2 cursor-pointer hover:bg-secondary/80 transition-colors duration-200"
                                                    onClick={() => setIsAddingPermission(true)}
                                                >
                                                    <PlusIcon className="w-4 h-4" /> 
                                                    <Translate id="add_permission" />
                                                </div>
                                            ))}
                                            {(!CanRankManageRank(player.rankId, member.rankId) && memberPermissions.length === 0) && (
                                                <div className="text-sm text-muted-foreground w-full whitespace-nowrap">
                                                    <Translate id="no_permissions" />
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div className="flex flex-col gap-2">
                            <div className="text-xl font-bold text-primary"><Translate id="recent_duty_logs" /></div>
                            <Table maxHeight={"280px"} sortFunction={(data, sortKey, sortDirection) => {
                                return data.sort((a, b) => {
                                    if (sortKey === "startTimestamp") {
                                        return sortDirection === 'desc' ? new Date(a.startTimestamp).getTime() - new Date(b.startTimestamp).getTime() : new Date(b.startTimestamp).getTime() - new Date(a.startTimestamp).getTime();
                                    } else if (sortKey === "finishTimestamp") {
                                        return sortDirection === 'desc' ? new Date(a.finishTimestamp).getTime() - new Date(b.finishTimestamp).getTime() : new Date(b.finishTimestamp).getTime() - new Date(a.finishTimestamp).getTime();
                                    } else if (sortKey === "duration") {
                                        return sortDirection === 'desc' ? (a.rawDuration) - (b.rawDuration) : (b.rawDuration) - (a.rawDuration);
                                    }
                                    return 0;
                                });
                            }} data={member.recentDutyLogs.map((log, index) => ({
                                ...log,
                                duration: GetStopwatchTime(log.duration),
                                rawDuration: log.duration,
                                startTimestamp: new Date(log.startTimestamp).toLocaleString(),
                                finishTimestamp: new Date(log.finishTimestamp).toLocaleString(),
                                action: (<div className="flex items-center gap-2">
                                    <Button variant="outline" size="icon" onClick={() => {
                                        openWindow("file", {
                                            header: {
                                                title: department.label.toUpperCase(),
                                                image: department.image,
                                                leftInfo: [`<b>${player.name}</b>`, `Los Santos, San Andreas`],
                                                rightInfo: [`<b>${memberRank.label}</b>`, `${new Date(Date.now()).toLocaleString()}`],
                                            },
                                            subContent: [],
                                            enableContent: true,
                                            content: log.report || "No report provided.",
                                            canEdit: false
                                        });
                                    }}>
                                        <EyeIcon className="w-4 h-4"/>
                                    </Button>
                                </div>)
                            }))} columns={[
                                {
                                    key: "startTimestamp",
                                    header: "Start Time",
                                    sortable: true,
                                },
                                {
                                    key: "finishTimestamp",
                                    header: "Finish Time",
                                    sortable: true,
                                },
                                {
                                    key: "duration",
                                    header: "Duration",
                                    sortable: true,
                                },
                                {
                                    key: "action",
                                    header: "",
                                    sortable: false,
                                }
                            ]} />
                            {member.recentDutyLogs.length <= 0 && (
                                <div className="text-sm text-muted-foreground text-center">
                                    <Translate id="no_recent_duty_logs" />
                                </div>
                            )}
                        </div>
                    </div>     
                </div>
            </div>
        </div>
    )
}

function SelectedRankModal({rankId, onClose, isModalVisible}: {rankId: number, onClose: () => void, isModalVisible: boolean}) {
    const { config } = useConfig();
    const { department, setDepartment } = useComputer();
    const rank = department.ranks.find((rank) => rank.rankId === rankId);
    const rankIndex = department.ranks.findIndex((rank) => rank.rankId === rankId);
    if (!rank) return null;
    const [inputLabel, setInputLabel] = useState(rank.label || "");
    const [inputJobLevel, setInputJobLevel] = useState(rank.jobLevel || 0);
    const [isEditingLabel, setIsEditingLabel] = useState(false);
    const [isEditingJobLevel, setIsEditingJobLevel] = useState(false);
    const [isAddingManagingRank, setIsAddingManagingRank] = useState(false);
    const [selectedManagingRank, setSelectedManagingRank] = useState<number | null>(null);
    const [inputSalary, setInputSalary] = useState(rank.salary || 0);
    const [isDeletingRank, setIsDeletingRank] = useState(false);
    let managingRankIds: number[] = [];
    for (let i = 0; i < rank.managingRankIds.length; i++) {
        managingRankIds.push(rank.managingRankIds[i]);
    }
    useEffect(() => {
        const debounceTimeout = setTimeout(() => {  
            fetchNui("updateComputerDepartment", {
                type: "updateRankSalary",
                rankId: rankId,
                salary: inputSalary,
            });
        }, 500);
        return () => clearTimeout(debounceTimeout);
    }, [inputSalary]);
    return (
        <div className={`absolute inset-0 bg-background/50 backdrop-blur-sm z-[50] flex items-center justify-center transition-opacity duration-200 ${isModalVisible ? 'opacity-100' : 'opacity-0'}`}>
            <div className="bg-background/95 w-[75%] h-[75%] shadow-lg transition-all duration-200">
                <div className="relative w-full h-[30px] bg-secondary flex items-center justify-between select-none">
                    <div className="flex items-center justify-center gap-2 pl-2">
                        <div className="font-semibold text-sm text-white">{rank.label || "Unknown"}</div>
                    </div>
                    <div className="flex items-center justify-center gap-2 hover:bg-destructive/50 transition-all duration-300 h-[30px] w-[30px] cursor-pointer" onClick={onClose}>
                        <X/>
                    </div>
                </div>
                <div className="w-full h-[calc(100%-30px)] p-2 overflow-y-auto">
                    <div className="flex flex-col gap-2">
                        <div className="flex flex-row items-center gap-4">
                            <div className="flex flex-col items-center gap-2">
                                <div className="flex flex-col gap-2">
                                    <div className="flex flex-row gap-2 items-center">
                                        <div className="text-sm font-semibold"><Translate id="label" />:</div>
                                        {isEditingLabel ? (
                                            <input type="text" className="text-sm bg-secondary px-2 rounded-md" value={inputLabel} onChange={(e) => setInputLabel(e.target.value)} />
                                        ) : (
                                            <div className="text-sm">{rank.label || "Unknown"}</div>
                                        )}
                                        <div className="cursor-pointer" onClick={() => {
                                            setIsEditingLabel(!isEditingLabel)
                                            if (isEditingLabel) {
                                                fetchNui("updateComputerDepartment", {
                                                    type: "updateRankLabel",
                                                    rankId: rankId,
                                                    label: inputLabel,
                                                });
                                                // setDepartment({
                                                //     ...department,
                                                //     ranks: department.ranks.map(rank => rank.rankId === rankId ? { ...rank, label: inputLabel } : rank),
                                                // });
                                            }
                                        }}>
                                            {isEditingLabel ? (
                                                <SaveIcon className="w-4 h-4" />
                                            ) : (
                                                <Edit className="w-4 h-4" />
                                            )}
                                        </div>
                                    </div>
                                    {rankIndex !== 0 && (
                                        <div className="flex flex-row gap-2 items-center">
                                            <div className="text-sm font-semibold"><Translate id="job_level" />:</div>
                                            <select className="text-sm bg-secondary px-2 rounded-md" value={inputJobLevel} onChange={(e) => {
                                                setInputJobLevel(parseInt(e.target.value))
                                                fetchNui("updateComputerDepartment", {
                                                    type: "updateRankJobLevel",
                                                    rankId: rankId,
                                                    jobLevel: parseInt(e.target.value),
                                                });
                                            }}>
                                                {Array.from({length: config.jobs[department.job].maxLevel}, (_, i) => (
                                                    <option key={i} value={i}>{i}</option>
                                                ))}
                                            </select>
                                        </div>
                                    )}
                                    <div className="flex flex-row gap-2 items-center">
                                        <div className="text-sm font-semibold"><Translate id="salary" />:</div>
                                        <input type="number" className="text-sm bg-secondary px-2 rounded-md" value={inputSalary} onChange={(e) => setInputSalary(parseInt(e.target.value))} />
                                    </div>
                                    {rankIndex !== 0 && (
                                        <div className="w-full select-none whitespace-nowrap flex items-center justify-center gap-2 bg-destructive hover:bg-destructive/80 transition-colors duration-200 cursor-pointer rounded-md p-1 font-semibold text-xs text-center" onClick={() => {
                                            if (isDeletingRank) {
                                                fetchNui("updateComputerDepartment", {
                                                    type: "deleteRank",
                                                    rankId: rankId,
                                                });
                                                // let newRanks = department.ranks.filter(r => r.rankId !== rankId);
                                                // let newMembers = [];
                                                // if (newRanks.length <= 1) {
                                                //     for (let i = 0; i < department.members.length; i++) {
                                                //         if (department.members[i].rankId !== rankId) {
                                                //             newMembers.push(department.members[i]);
                                                //         }
                                                //     }
                                                // }
                                                // else {
                                                //     newMembers = department.members.map(m => m.rankId === rankId ? {
                                                //         ...m,
                                                //         rankId: newRanks[newRanks.length - 1].rankId,
                                                //     } : m);
                                                // }
                                                setIsDeletingRank(false);
                                                // setDepartment({
                                                //     ...department,
                                                //     ranks: newRanks,
                                                //     members: newMembers,
                                                // });
                                                onClose();
                                            } else {
                                                setIsDeletingRank(true);
                                            }
                                        }}>
                                            <Trash className="w-3 h-3" />
                                            {isDeletingRank ? (
                                                <Translate id="confirm_delete_rank" />
                                            ) : (
                                                <Translate id="delete_rank" />
                                            )}
                                        </div>    
                                    )}
                                    {department.ranks[0].rankId !== rankId && (
                                        <div className="flex flex-col gap-2">
                                            <div className="text-sm font-semibold"><Translate id="managing_ranks" />:</div>
                                            <div className="grid grid-cols-5 gap-2">
                                                {managingRankIds.map((targetRankId) => (
                                                    <div key={targetRankId}>
                                                        <div className="relative text-sm bg-secondary rounded-md p-1 text-center px-2">
                                                            {department.ranks.find((rank) => rank.rankId === targetRankId)?.label || "Unknown"}
                                                            <div className="absolute inset-0 bg-destructive/95 rounded-md flex items-center justify-center opacity-0 hover:opacity-100 transition-opacity duration-200 cursor-pointer" onClick={() => {
                                                                // let newManagingRankIds = managingRankIds.filter(id => id !== targetRankId);
                                                                // setDepartment({
                                                                //     ...department,
                                                                //     ranks: department.ranks.map(rank => rank.rankId === rankId ? { ...rank, managingRankIds: newManagingRankIds } : rank),
                                                                // });
                                                                fetchNui("updateComputerDepartment", {
                                                                    type: "deleteRankManager",
                                                                    rankId: rankId,
                                                                    managingRankId: targetRankId,
                                                                });
                                                            }}>
                                                                <X className="w-4 h-4 text-white" />
                                                            </div>
                                                        </div>
                                                    </div>
                                                ))}
                                                {isAddingManagingRank ? (
                                                    <div className="bg-secondary rounded-md p-1">
                                                        <select 
                                                            className="w-full bg-background text-xs p-1 rounded border border-border"
                                                            value={selectedManagingRank || ""}
                                                            onChange={(e) => setSelectedManagingRank(parseInt(e.target.value))}
                                                        >
                                                            <option value="">Select rank...</option>
                                                            {department.ranks.map((targetRank, targetRankIndex) => (rankIndex > targetRankIndex && targetRankIndex !== 0) && (
                                                                <option key={targetRankIndex} value={targetRank.rankId}>
                                                                    {targetRank.label}
                                                                </option>
                                                            ))}
                                                        </select>
                                                        <div className="flex gap-1 mt-2">
                                                            <button 
                                                                className="flex-1 bg-green-600 hover:bg-green-700 text-white text-xs p-1 rounded flex items-center justify-center gap-1"
                                                                onClick={() => {
                                                                    if (selectedManagingRank) {
                                                                        fetchNui("updateComputerDepartment", {
                                                                            type: "addRankManager",
                                                                            rankId: rankId,
                                                                            managingRankId: selectedManagingRank,
                                                                        });
                                                                        // let newManagingRankIds = [...managingRankIds, selectedManagingRank];
                                                                        // setDepartment({
                                                                        //     ...department,
                                                                        //     ranks: department.ranks.map(rank => rank.rankId === rankId ? { ...rank, managingRankIds: newManagingRankIds } : rank),
                                                                        // });
                                                                        setSelectedManagingRank(null);
                                                                        setIsAddingManagingRank(false);
                                                                    }
                                                                }}
                                                            >
                                                                <Check className="w-3 h-3" />
                                                                Save
                                                            </button>
                                                            <button 
                                                                className="flex-1 bg-gray-600 hover:bg-gray-700 text-white text-xs p-1 rounded flex items-center justify-center gap-1"
                                                                onClick={() => {
                                                                    setSelectedManagingRank(null);
                                                                    setIsAddingManagingRank(false);
                                                                }}
                                                            >
                                                                <X className="w-3 h-3" />
                                                                Cancel
                                                            </button>
                                                        </div>
                                                    </div>
                                                ) : (
                                                    <div className="text-sm cursor-pointer bg-secondary rounded-md p-1 text-center flex items-center justify-center gap-1 whitespace-nowrap" onClick={() => {
                                                        setIsAddingManagingRank(true);
                                                    }}>
                                                        <PlusIcon className="w-4 h-4" />
                                                        <Translate id="add_rank_manager" />
                                                    </div>
                                                )}
                                            </div>
                                        </div>
                                    )}
                                    {rankIndex !== 0 && (
                                        <>
                                            <div className="text-sm font-semibold"><Translate id="police_armory" />:</div>
                                            <div className="grid grid-cols-5 gap-2 overflow-y-auto max-h-[250px] px-2">
                                                {config.policeArmory.map((item: any, index: number) => {
                                                    const isIncluded = rank.armory.includes(item.name);
                                                    return (
                                                        <div key={index} className="relative bg-secondary/25 rounded-md p-1 group">
                                                            <ItemDisplay item={item} />
                                                            {isIncluded ? (
                                                                <div
                                                                    className="absolute z-10 inset-0 bg-green-500/25 rounded-md flex items-center justify-center opacity-100 group-hover:bg-red-500/50 group-hover:opacity-100 transition-all duration-200 cursor-pointer"
                                                                    onClick={() => {
                                                                        fetchNui("updateComputerDepartment", {
                                                                            type: "deleteRankArmory",
                                                                            rankId: rankId,
                                                                            item: item.name,
                                                                        });
                                                                        // If hovered, remove; otherwise do nothing
                                                                        // setDepartment({
                                                                        //     ...department,
                                                                        //     ranks: department.ranks.map(rank => rank.rankId === rankId ? { ...rank, armory: rank.armory.filter((i: string) => i !== item.name) } : rank),
                                                                        // });
                                                                    }}
                                                                >
                                                                    <span className="flex items-center justify-center">
                                                                        <CheckIcon className={`w-8 h-8 text-white transition-opacity duration-200 ${isIncluded ? 'opacity-100' : 'opacity-0'} group-hover:hidden`} />
                                                                        <X className="w-8 h-8 text-white absolute opacity-0 group-hover:opacity-100 transition-opacity duration-200" />
                                                                    </span>
                                                                </div>
                                                            ) : (
                                                                <div
                                                                    className="absolute z-10 inset-0 bg-green-500/50 rounded-md flex items-center justify-center opacity-0 hover:opacity-100 transition-opacity duration-200 cursor-pointer"
                                                                    onClick={() => {
                                                                        fetchNui("updateComputerDepartment", {
                                                                            type: "addRankArmory",
                                                                            rankId: rankId,
                                                                            item: item.name,
                                                                        });
                                                                        // setDepartment({
                                                                        //     ...department,
                                                                        //     ranks: department.ranks.map(rank => rank.rankId === rankId ? { ...rank, armory: [...rank.armory, item.name] } : rank),
                                                                        // });
                                                                    }}
                                                                >
                                                                    <CheckIcon className="w-8 h-8 text-white" />
                                                                </div>
                                                            )}
                                                        </div>
                                                    );
                                                })}
                                            </div>
                                            <div className="text-sm font-semibold"><Translate id="police_garage" />:</div>
                                            <div className="grid grid-cols-5 gap-2 overflow-y-auto max-h-[250px] px-2">
                                                {config.policeGarage.map((item: any) => {
                                                    const isIncluded = rank.vehicles.includes(item.model);
                                                    return (
                                                        <div key={item.model} className="relative bg-secondary/25 rounded-md p-1 group">
                                                            <ItemDisplay item={{
                                                                label: item.label,
                                                                image: item.image,
                                                                name: item.model,
                                                                itemType: "vehicle",
                                                            }} />
                                                            {isIncluded ? (
                                                                <div
                                                                    className="absolute z-10 inset-0 bg-green-500/25 rounded-md flex items-center justify-center opacity-100 group-hover:bg-red-500/50 group-hover:opacity-100 transition-all duration-200 cursor-pointer"
                                                                    onClick={() => {
                                                                        fetchNui("updateComputerDepartment", {
                                                                            type: "deleteRankVehicle",
                                                                            rankId: rankId,
                                                                            vehicle: item.model,
                                                                        });
                                                                        // If hovered, remove; otherwise do nothing
                                                                        // setDepartment({
                                                                        //     ...department,
                                                                        //     ranks: department.ranks.map(rank => rank.rankId === rankId ? { ...rank, vehicles: rank.vehicles.filter((i: number) => i !== item.model) } : rank),
                                                                        // });
                                                                    }}
                                                                >
                                                                    <span className="flex items-center justify-center">
                                                                        <CheckIcon className={`w-8 h-8 text-white transition-opacity duration-200 ${isIncluded ? 'opacity-100' : 'opacity-0'} group-hover:hidden`} />
                                                                        <X className="w-8 h-8 text-white absolute opacity-0 group-hover:opacity-100 transition-opacity duration-200" />
                                                                    </span>
                                                                </div>
                                                            ) : (
                                                                <div
                                                                    className="absolute z-10 inset-0 bg-green-500/50 rounded-md flex items-center justify-center opacity-0 hover:opacity-100 transition-opacity duration-200 cursor-pointer"
                                                                    onClick={() => {
                                                                        fetchNui("updateComputerDepartment", {
                                                                            type: "addRankVehicle",
                                                                            rankId: rankId,
                                                                            vehicle: item.model,
                                                                        });
                                                                        // setDepartment({
                                                                        //     ...department,
                                                                        //     ranks: department.ranks.map(rank => rank.rankId === rankId ? { ...rank, vehicles: [...rank.vehicles, item.model] } : rank),
                                                                        // });
                                                                    }}
                                                                >
                                                                    <CheckIcon className="w-8 h-8 text-white" />
                                                                </div>
                                                            )}
                                                        </div>
                                                    );
                                                })}
                                            </div>
                                        </>
                                    )}
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    )
}

function SelectedPermissionModal({permission, onClose, isModalVisible}: {permission: string, onClose: () => void, isModalVisible: boolean}) {
    const { config } = useConfig();
    const { department, setDepartment } = useComputer();
    const [isAddingPermissionManager, setIsAddingPermissionManager] = useState(false);
    const [selectedManagingRank, setSelectedManagingRank] = useState<number | null>(null);
    const [isDeletingPermission, setIsDeletingPermission] = useState(false);
    if (!department.permissions[permission]) return null;
    return (
        <div className={`absolute inset-0 bg-background/50 backdrop-blur-sm z-[50] flex items-center justify-center transition-opacity duration-200 ${isModalVisible ? 'opacity-100' : 'opacity-0'}`}>
            <div className="bg-background/95 w-[75%] h-[75%] shadow-lg transition-all duration-200">
                <div className="relative w-full h-[30px] bg-secondary flex items-center justify-between select-none">
                    <div className="flex items-center justify-center gap-2 pl-2">
                        <div className="font-semibold text-sm text-white">{permission}</div>
                    </div>
                    <div className="flex items-center justify-center gap-2 hover:bg-destructive/50 transition-all duration-300 h-[30px] w-[30px] cursor-pointer" onClick={onClose}>
                        <X/>
                    </div>
                </div>
                <div className="w-full h-[calc(100%-30px)] p-2 overflow-y-auto">
                    <div className="flex flex-col gap-2">
                        <div className="flex flex-row items-center gap-4">
                            <div className="flex flex-col items-center gap-2">
                                <div className="flex flex-col gap-2">
                                    <div className="flex flex-row gap-2 items-center">
                                        <div className="text-sm font-semibold"><Translate id="label" />:</div>
                                        <div className="text-sm">{permission}</div>
                                    </div>
                                    <div className="w-full select-none whitespace-nowrap flex items-center justify-center gap-2 bg-destructive hover:bg-destructive/80 transition-colors duration-200 cursor-pointer rounded-md p-1 font-semibold text-xs text-center" onClick={() => {
                                        if (isDeletingPermission) {
                                            fetchNui("updateComputerDepartment", {
                                                type: "deletePermission",
                                                label: permission,
                                            });
                                            setIsDeletingPermission(false);
                                            // setDepartment({
                                            //     ...department,
                                            //     permissions: Object.fromEntries(Object.entries(department.permissions).filter(([key]) => key !== permission)),
                                            // });
                                            onClose();
                                        } else {
                                            setIsDeletingPermission(true);
                                        }
                                    }}>
                                        <Trash className="w-3 h-3" />
                                        {isDeletingPermission ? (
                                            <Translate id="confirm_delete_permission" />
                                        ) : (
                                            <Translate id="delete_permission" />
                                        )}
                                    </div> 
                                    <div className="text-sm font-semibold"><Translate id="managing_ranks" />:</div>
                                    <div className="grid grid-cols-5 gap-2">
                                        {department.permissions[permission].managingRankIds.map((targetRankId) => (
                                            <div key={targetRankId}>
                                                <div className="relative text-sm bg-secondary rounded-md p-1 text-center px-2">
                                                    {department.ranks.find((rank) => rank.rankId === targetRankId)?.label || "Unknown"}
                                                    <div className="absolute inset-0 bg-destructive/95 rounded-md flex items-center justify-center opacity-0 hover:opacity-100 transition-opacity duration-200 cursor-pointer" onClick={() => {
                                                        fetchNui("updateComputerDepartment", {
                                                            type: "deletePermissionRankManager",
                                                            permission: permission,
                                                            managingRankId: targetRankId,
                                                        });
                                                        // setDepartment({
                                                        //     ...department,
                                                        //     permissions: {
                                                        //         ...department.permissions,
                                                        //         [permission]: {
                                                        //             ...department.permissions[permission],
                                                        //             managingRankIds: department.permissions[permission].managingRankIds.filter(id => id !== targetRankId),
                                                        //         },
                                                        //     },
                                                        // });
                                                    }}>
                                                        <X className="w-4 h-4 text-white" />
                                                    </div>
                                                </div>
                                            </div>
                                        ))}
                                        {isAddingPermissionManager ? (
                                            <div className="bg-secondary rounded-md p-1">
                                                <select 
                                                    className="w-full bg-background text-xs p-1 rounded border border-border"
                                                    value={selectedManagingRank || ""}
                                                    onChange={(e) => setSelectedManagingRank(parseInt(e.target.value))}
                                                >
                                                    <option value="">Select rank...</option>
                                                    {department.ranks.map((targetRank, targetRankIndex) => (!department.permissions[permission].managingRankIds.includes(targetRank.rankId) && targetRankIndex !== 0) && (
                                                        <option key={targetRankIndex} value={targetRank.rankId}>
                                                            {targetRank.label}
                                                        </option>
                                                    ))}
                                                </select>
                                                <div className="flex gap-1 mt-2">
                                                    <button 
                                                        className="flex-1 bg-green-600 hover:bg-green-700 text-white text-xs p-1 rounded flex items-center justify-center gap-1"
                                                        onClick={() => {
                                                            if (selectedManagingRank) {
                                                                fetchNui("updateComputerDepartment", {
                                                                    type: "addPermissionRankManager",
                                                                    permission: permission,
                                                                    managingRankId: selectedManagingRank,
                                                                });
                                                                // setDepartment({
                                                                //     ...department,
                                                                //     permissions: {
                                                                //         ...department.permissions,
                                                                //         [permission]: {
                                                                //             ...department.permissions[permission],
                                                                //             managingRankIds: [...department.permissions[permission].managingRankIds, selectedManagingRank],
                                                                //         },
                                                                //     },
                                                                // });
                                                                setSelectedManagingRank(null);
                                                                setIsAddingPermissionManager(false);
                                                            }
                                                        }}
                                                    >
                                                        <Check className="w-3 h-3" />
                                                        Save
                                                    </button>
                                                    <button 
                                                        className="flex-1 bg-gray-600 hover:bg-gray-700 text-white text-xs p-1 rounded flex items-center justify-center gap-1"
                                                        onClick={() => {
                                                            setSelectedManagingRank(null);
                                                            setIsAddingPermissionManager(false);
                                                        }}
                                                    >
                                                        <X className="w-3 h-3" />
                                                        Cancel
                                                    </button>
                                                </div>
                                            </div>
                                        ) : (
                                            <div className="text-sm cursor-pointer bg-secondary rounded-md p-1 text-center flex items-center justify-center gap-1 whitespace-nowrap" onClick={() => {
                                                setIsAddingPermissionManager(true);
                                            }}>
                                                <PlusIcon className="w-4 h-4" />
                                                <Translate id="add_rank_manager" />
                                            </div>
                                        )}
                                    </div>
                                    <div className="text-sm font-semibold"><Translate id="police_armory" />:</div>
                                    <div className="grid grid-cols-5 gap-2 overflow-y-auto max-h-[250px] px-2">
                                        {config.policeArmory.map((item: any) => {
                                            const isIncluded = department.permissions[permission]?.armory?.includes(item.name);
                                            return (
                                                <div key={item.name} className="relative bg-secondary/25 rounded-md p-1 group">
                                                    <ItemDisplay item={{
                                                        label: item.label,
                                                        name: item.name,
                                                        itemType: item.itemType || "item",
                                                    }} />
                                                    {isIncluded ? (
                                                        <div
                                                            className="absolute z-10 inset-0 bg-green-500/25 rounded-md flex items-center justify-center opacity-100 group-hover:bg-red-500/50 group-hover:opacity-100 transition-all duration-200 cursor-pointer"
                                                            onClick={() => {
                                                                // If hovered, remove; otherwise do nothing
                                                                fetchNui("updateComputerDepartment", {
                                                                    type: "deletePermissionArmory",
                                                                    permission: permission,
                                                                    item: item.name,
                                                                });
                                                                // setDepartment({
                                                                //     ...department,
                                                                //     permissions: {
                                                                //         ...department.permissions,
                                                                //         [permission]: {
                                                                //             ...department.permissions[permission],
                                                                //             armory: department.permissions[permission].armory.filter((i: string) => i !== item.name),
                                                                //         },
                                                                //     },
                                                                // });
                                                            }}
                                                        >
                                                            <span className="flex items-center justify-center">
                                                                <CheckIcon className={`w-8 h-8 text-white transition-opacity duration-200 ${isIncluded ? 'opacity-100' : 'opacity-0'} group-hover:hidden`} />
                                                                <X className="w-8 h-8 text-white absolute opacity-0 group-hover:opacity-100 transition-opacity duration-200" />
                                                            </span>
                                                        </div>
                                                    ) : (
                                                        <div
                                                            className="absolute z-10 inset-0 bg-green-500/50 rounded-md flex items-center justify-center opacity-0 hover:opacity-100 transition-opacity duration-200 cursor-pointer"
                                                            onClick={() => {
                                                                fetchNui("updateComputerDepartment", {
                                                                    type: "addPermissionArmory",
                                                                    permission: permission,
                                                                    item: item.name,
                                                                });
                                                                // setDepartment({
                                                                //     ...department,
                                                                //     permissions: {
                                                                //         ...department.permissions,
                                                                //         [permission]: {
                                                                //             ...department.permissions[permission],
                                                                //             armory: [...department.permissions[permission].armory, item.name],
                                                                //         },
                                                                //     },
                                                                // });
                                                            }}
                                                        >
                                                            <CheckIcon className="w-8 h-8 text-white" />
                                                        </div>
                                                    )}
                                                </div>
                                            );
                                        })}
                                    </div>
                                    <div className="text-sm font-semibold"><Translate id="police_garage" />:</div>
                                    <div className="grid grid-cols-5 gap-2 overflow-y-auto max-h-[250px] px-2">
                                        {config.policeGarage.map((item: any) => {
                                            const isIncluded = department.permissions[permission]?.vehicles?.includes(item.model);
                                            return (
                                                <div key={item.model} className="relative bg-secondary/25 rounded-md p-1 group">
                                                    <ItemDisplay item={{
                                                        label: item.label,
                                                        name: item.model,
                                                        image: item.image,
                                                        itemType: "vehicle",
                                                    }} />
                                                    {isIncluded ? (
                                                        <div
                                                            className="absolute z-10 inset-0 bg-green-500/25 rounded-md flex items-center justify-center opacity-100 group-hover:bg-red-500/50 group-hover:opacity-100 transition-all duration-200 cursor-pointer"
                                                            onClick={() => {
                                                                // If hovered, remove; otherwise do nothing
                                                                fetchNui("updateComputerDepartment", {
                                                                    type: "deletePermissionVehicle",
                                                                    permission: permission,
                                                                    vehicle: item.model,
                                                                });
                                                                // setDepartment({
                                                                //     ...department,
                                                                //     permissions: {
                                                                //         ...department.permissions,
                                                                //         [permission]: {
                                                                //             ...department.permissions[permission],
                                                                //             vehicles: department.permissions[permission].vehicles.filter((i: number) => i !== item.model),
                                                                //         },
                                                                //     },
                                                                // });
                                                            }}
                                                        >
                                                            <span className="flex items-center justify-center">
                                                                <CheckIcon className={`w-8 h-8 text-white transition-opacity duration-200 ${isIncluded ? 'opacity-100' : 'opacity-0'} group-hover:hidden`} />
                                                                <X className="w-8 h-8 text-white absolute opacity-0 group-hover:opacity-100 transition-opacity duration-200" />
                                                            </span>
                                                        </div>
                                                    ) : (
                                                        <div
                                                            className="absolute z-10 inset-0 bg-green-500/50 rounded-md flex items-center justify-center opacity-0 hover:opacity-100 transition-opacity duration-200 cursor-pointer"
                                                            onClick={() => {
                                                                fetchNui("updateComputerDepartment", {
                                                                    type: "addPermissionVehicle",
                                                                    permission: permission,
                                                                    vehicle: item.model,
                                                                });
                                                                // setDepartment({
                                                                //     ...department,
                                                                //     permissions: {
                                                                //         ...department.permissions,
                                                                //         [permission]: {
                                                                //             ...department.permissions[permission],
                                                                //             vehicles: [...department.permissions[permission].vehicles, item.model],
                                                                //         },
                                                                //     },
                                                                // });
                                                            }}
                                                        >
                                                            <CheckIcon className="w-8 h-8 text-white" />
                                                        </div>
                                                    )}
                                                </div>
                                            );
                                        })}
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    )
}

function Roster() {
    const { department, player, setDepartment } = useComputer();
    const [selectedMember, setSelectedMember] = useState<DepartmentMember | null>(null);
    const [isModalVisible, setIsModalVisible] = useState(false);
    const [section, setSection] = useState("roster");
    const [selectedRank, setSelectedRank] = useState<number | null>(0);
    const [rankLabel, setRankLabel] = useState("");
    const [isCreatingRank, setIsCreatingRank] = useState(false);
    const [isAddingMember, setIsAddingMember] = useState(false);
    const [memberIdentifier, setMemberIdentifier] = useState(-1);
    const [selectedPermission, setSelectedPermission] = useState<string | null>(null);
    const [isCreatingPermission, setIsCreatingPermission] = useState(false);
    const [permissionLabel, setPermissionLabel] = useState("");
    const [nearbyPlayersState, setNearbyPlayers] = useState<Player[]>([]);
    const { config } = useConfig();
    const nearbyPlayers = nearbyPlayersState.filter((player: any) => !department.members.some((member: any) => member.identifier === player.identifier));
    useEffect(() => {
        fetchNui("getNearbyPlayers", {}).then((data: any) => {
            const filtered = data.filter((player: any) => !department.members.some((member: any) => member.identifier === player.identifier));
            if (filtered.length > 0) {
                setMemberIdentifier(0);
            }
            setNearbyPlayers(filtered);
        });
    }, []);
    const rankIndex = department.ranks.findIndex((rank) => rank.rankId === player?.rankId);
    const canAddMembers = department.ranks.some(rank => rank.managingRankIds.includes(player?.rankId)) || rankIndex == 0;
    let tabs = ["roster"];
    if (rankIndex == 0) {
        tabs.push("ranks");
        tabs.push("permissions");
    }
    const handleMemberSelect = (member: DepartmentMember) => {
        setSelectedMember(member);
        setTimeout(() => {
            setIsModalVisible(true);
        }, 10);
    };

    const handleMemberDeselect = () => {
        setIsModalVisible(false);
        setTimeout(() => {
            setSelectedMember(null);
        }, 200);
    };

    const handleRankSelect = (rankId: number) => {
        setSelectedRank(rankId);
        setTimeout(() => {
            setIsModalVisible(true);
        }, 10);
    };

    const handleRankDeselect = () => {
        setIsModalVisible(false);
        setTimeout(() => {
            setSelectedRank(null);
        }, 200);
    };

    const handlePermissionSelect = (permission: string) => {
        setSelectedPermission(permission);
        setTimeout(() => {
            setIsModalVisible(true);
        }, 10);
    };

    const handlePermissionDeselect = () => {
        setIsModalVisible(false);
        setTimeout(() => {
            setSelectedPermission(null);
        }, 200);
    };
    return (
        <div className="relative h-full flex flex-col gap-0">
            {(selectedMember) && (
                <SelectedMemberModal memberIdentifier={selectedMember.identifier} onClose={handleMemberDeselect} isModalVisible={isModalVisible} />
            )}
            {(selectedRank && rankIndex == 0) ? (
                <SelectedRankModal rankId={selectedRank} onClose={handleRankDeselect} isModalVisible={isModalVisible} />
            ) : null}
            {(selectedPermission && rankIndex == 0) && (
                <SelectedPermissionModal permission={selectedPermission} onClose={handlePermissionDeselect} isModalVisible={isModalVisible} />
            )}
            {(tabs.length > 1 || canAddMembers) && (
            <div className="w-full p-2 select-none flex flex-col gap-2">
                {tabs.length > 1 && (
                    <div className="font-semibold text-lg text-primary w-full flex flex-row gap-0 bg-secondary py-1 px-1 gap-1 rounded-md">
                        {tabs.map((tab) => (
                            <div className={`px-4 cursor-pointer hover:bg-white/10 transition-all duration-200 rounded-md ${section === tab ? "bg-white/10" : ""}`} onClick={() => setSection(tab)}>
                                <Translate id={tab} />
                            </div>
                        ))}
                    </div>
                )}
                {section === "roster" && (
                    <div className="w-full bg-secondary flex items-center justify-center select-none rounded-md h-[40px]" style={{
                        cursor: !isAddingMember ? "pointer" : "default",
                    }} onClick={() => {
                        if (!isAddingMember) {
                            setIsAddingMember(true);
                        }
                    }}>
                        {isAddingMember ? (
                            <div className="flex items-center justify-center gap-2">
                                <select className="text-sm bg-background/75 px-2 rounded-md h-[36px]" value={memberIdentifier} onChange={(e) => setMemberIdentifier(parseInt(e.target.value))}>
                                    {nearbyPlayers.map((player, index) => (
                                        <option key={index} value={index}>[{player.source}]: {player.name}</option>
                                    ))}
                                    {nearbyPlayers.length === 0 && (
                                        <option value={-1}>{translateText(config, "no_nearby_players", [])}</option>
                                    )}
                                </select>
                                <Button variant="outline" size="icon" onClick={() => {
                                    if (memberIdentifier === -1) return;
                                    setIsAddingMember(false);
                                    fetchNui("updateComputerDepartment", {
                                        type: "addMember",
                                        source: nearbyPlayers[memberIdentifier].source,
                                    });
                                }}>
                                    <SaveIcon className="w-4 h-4" />
                                </Button>
                                <Button variant="outline" size="icon" onClick={() => {
                                    setIsAddingMember(false);
                                }}>
                                    <X className="w-4 h-4" />
                                </Button>
                            </div>
                        ) : (
                            <div className="flex items-center justify-center gap-0">
                                <PlusIcon className="w-4 h-4" />
                                <div className="font-semibold text-md text-white rounded-md"><Translate id="add_member" /></div>
                            </div>
                        )}
                    </div>
                )}
            </div>
            )}
            {section === "roster" && (
                <Table maxHeight="100%" defaultSortKey="rank" data={department.members?.map((member) => ({
                    ...member,
                    rank: department.ranks.find((rank) => rank.rankId === member.rankId)?.label || "Unknown",
                    rankIndex: department.ranks.findIndex((rank) => rank.rankId === member.rankId),
                    onDutyTimeDisplay: GetStopwatchTime(member.onDutyTime),
                    lastShift: member.recentDutyLogs.length > 0 ? new Date((member.recentDutyLogs[0].finish - member.recentDutyLogs[0].duration) * 1000).toLocaleString() : "Never",
                    action: (<div className="flex items-center gap-2 justify-end">
                        {member.onDuty && (
                            <Button variant="outline" size="icon" onClick={() => {
                                fetchNui("viewBodycam", {
                                    identifier: member.identifier,
                                });
                            }} >
                                <EyeIcon className="w-4 h-4"/>
                            </Button>
                        )}
                        <Button variant="outline" size="icon" onClick={() => handleMemberSelect(member)} >
                            <InfoIcon className="w-4 h-4"/>
                        </Button>
                    </div>)
                })) || []} columns={
                    [
                        {
                            key: "name",
                            header: "Name",
                            sortable: true,
                        },
                        {
                            key: "rank",
                            header: "Rank",
                            sortable: true,
                        },
                        {
                            key: "lastShift",
                            header: "Last Shift",
                            sortable: true,
                        },
                        {
                            key: "onDutyTimeDisplay",
                            header: "On Duty Time",
                            sortable: true,
                        },
                        {
                            key: "action",
                            header: "",
                            sortable: false,
                        }
                    ]
                } sortFunction={(data, sortKey, sortDirection) => {
                    return data.sort((a, b) => {
                        let comparison = 0;
                        
                        if (sortKey === "name") {
                            comparison = a.name.localeCompare(b.name);
                        } else if (sortKey === "rank") {
                            comparison = a.rankIndex - b.rankIndex;
                        } else if (sortKey === "onDutyTimeDisplay") {
                            comparison = a.onDutyTime - b.onDutyTime;
                        } else if (sortKey === "lastShift") {
                            if (a.recentDutyLogs.length > 0 && b.recentDutyLogs.length > 0) {
                                comparison = a.recentDutyLogs[0].finish - b.recentDutyLogs[0].finish;
                            } else {
                                comparison = a.recentDutyLogs.length - b.recentDutyLogs.length;
                            }
                        }
                        
                        return sortDirection === 'desc' ? -comparison : comparison;
                    });
                }} />
            )}
            {section === "ranks" && (rankIndex == 0) && (   
                <div className="w-full h-full flex flex-col overflow-y-auto select-none">
                    {department.ranks.map((rank, index) => (
                        <div 
                            key={rank.rankId} 
                            className="flex flex-row gap-2 p-[12px] transition-all duration-200 items-center"
                            style={{
                                backgroundColor: index % 2 === 0 ? "rgba(255, 255, 255, 0.1)" : "rgba(255, 255, 255, 0.05)"
                            }}
                        >
                            <Button variant="outline" size="icon" onClick={() => handleRankSelect(rank.rankId)}>
                                <Pencil className="w-4 h-4" />
                            </Button>
                            <div className="flex flex-col gap-1 items-center justify-center">
                                <div className="text-xs text-muted-foreground cursor-pointer hover:text-primary transition-all duration-200" onClick={() => {
                                    fetchNui("updateComputerDepartment", {
                                        type: "moveRank",
                                        rankId: rank.rankId,
                                        up: true,
                                    });
                                }}>
                                    <ArrowUp className="w-4 h-4" />
                                </div>
                                <div className="text-xs text-muted-foreground cursor-pointer hover:text-primary transition-all duration-200" onClick={() => {
                                    fetchNui("updateComputerDepartment", {
                                        type: "moveRank",
                                        rankId: rank.rankId,
                                        up: false,
                                    });
                                }}>
                                    <ArrowDown className="w-4 h-4" />
                                </div>
                            </div>
                            <div className="text-md flex-1 p-2">{rank.label}</div>
                        </div>
                    ))}
                    <div 
                        key={-1} 
                        className={`flex flex-row gap-2 p-[12px] transition-all duration-200 items-center ${!isCreatingRank ? "cursor-pointer" : ""}`}
                        style={{
                            backgroundColor: department.ranks.length % 2 === 0 ? "rgba(255, 255, 255, 0.1)" : "rgba(255, 255, 255, 0.05)"
                        }}
                        onClick={() => {
                            if (!isCreatingRank) {
                                setIsCreatingRank(true);
                            }
                        }}
                    >
                        {isCreatingRank ? (
                            <div className="flex flex-row gap-2 items-center">
                                <input type="text" className="text-sm h-[36px] bg-background/75 px-2 rounded-md" value={rankLabel} onChange={(e) => setRankLabel(e.target.value)} />
                                <Button variant="outline" size="icon" onClick={() => {
                                    fetchNui("updateComputerDepartment", {
                                        type: "addRank",
                                        label: rankLabel,
                                    });
                                    setIsCreatingRank(false);
                                }}>
                                    <SaveIcon className="w-4 h-4" />
                                </Button>
                                <Button variant="outline" size="icon" onClick={() => {
                                    setIsCreatingRank(false);
                                }}>
                                    <X className="w-4 h-4" />
                                </Button>
                            </div>
                        ) : (
                            <div className="flex gap-2 items-center">
                                <PlusIcon className="w-4 h-4" />
                                <Translate id="add_rank" />
                            </div>
                        )}
                    </div>
                </div>
            )}
            {section === "permissions" && (rankIndex == 0) && (
                <div className="w-full h-full flex flex-col overflow-y-auto">
                    {Object.keys(department.permissions).map((permission, index) => (
                        <div 
                            key={permission} 
                            onClick={() => handlePermissionSelect(permission)}
                            className={`flex flex-row gap-2 p-[12px] transition-all duration-200 items-center cursor-pointer`}
                            style={{
                                backgroundColor: index % 2 === 0 ? "rgba(255, 255, 255, 0.1)" : "rgba(255, 255, 255, 0.05)"
                            }}
                        >
                            <div className="text-md flex-1">{permission}</div>
                        </div>
                    ))}
                    <div 
                        key={-1} 
                        className={`flex flex-row gap-2 p-[12px] transition-all duration-200 items-center ${!isCreatingPermission ? "cursor-pointer" : ""}`}
                        style={{
                            backgroundColor: Object.keys(department.permissions).length % 2 === 0 ? "rgba(255, 255, 255, 0.1)" : "rgba(255, 255, 255, 0.05)"
                        }}
                        onClick={() => {
                            if (!isCreatingPermission) {
                                setIsCreatingPermission(true);
                            }
                        }}
                    >   
                        {isCreatingPermission ? (
                            <div className="flex flex-row gap-2 items-center">
                                <input type="text" className="text-sm h-[36px] bg-background/75 px-2 rounded-md" value={permissionLabel} onChange={(e) => setPermissionLabel(e.target.value)} />
                                <Button variant="outline" size="icon" onClick={() => {
                                    if (permissionLabel.length === 0 || Object.keys(department.permissions).includes(permissionLabel)) return;
                                    setIsCreatingPermission(false);
                                    fetchNui("updateComputerDepartment", {
                                        type: "addPermission",
                                        label: permissionLabel,
                                    });
                                    // setDepartment({
                                    //     ...department,
                                    //     permissions: {
                                    //         ...department.permissions,
                                    //         [permissionLabel]: { managingRankIds: [], armory: [], vehicles: [] },
                                    //     },
                                    // });
                                }}>
                                    <SaveIcon className="w-4 h-4" />
                                </Button>
                                <Button variant="outline" size="icon" onClick={() => {
                                    setIsCreatingPermission(false);
                                }}>
                                    <X className="w-4 h-4" />
                                </Button>
                            </div>
                        ) : (
                            <div className="flex gap-2 items-center">
                                <PlusIcon className="w-4 h-4" />
                                <Translate id="add_permission" />
                            </div>
                        )}
                    </div>
                </div>
            )}
        </div>
    )
}

export default function RosterPage() {
    return (
        <div className="relative w-full h-full" style={{
        }}>
            <Roster/>
        </div>
    )
}