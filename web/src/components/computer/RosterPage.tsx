import { useNuiEvent } from "@/providers/nui/useNui";
import { useContext, useState } from "react";
import Table from "../table/Table";
import { Translate } from "@/providers/locale/Locale";
import { Button } from "../ui/button";
import { Check, EyeIcon, PlusIcon, X } from "lucide-react";
import ComputerContext, { useComputer } from "./Computer";
import { usePlayer } from "@/providers/player/player";

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
    onDutyTime: number;
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

export function CanRankManageRank(rankId: number, managingRankId: number) {
    const { department } = useComputer();
    if (rankId === managingRankId) return false;
    const rank = department.ranks.find((rank) => rank.rankId === rankId);
    if (!rank) return false;
    if (department.ranks[0].rankId === rankId) return true;
    return rank.managingRankIds.includes(managingRankId);
}

function SelectedMemberModal({memberIdentifier, onClose, isModalVisible}: {memberIdentifier: string, onClose: () => void, isModalVisible: boolean}) {
    const { department, setDepartment, openWindow } = useComputer();
    const { player } = usePlayer();
    const [isAddingPermission, setIsAddingPermission] = useState(false);
    const [selectedPermission, setSelectedPermission] = useState("");
    const member = department.members.find((m) => m.identifier === memberIdentifier);
    if (!member) return null;
    return (
        <div className={`absolute inset-0 bg-background/50 backdrop-blur-sm z-[50] flex items-center justify-center transition-opacity duration-200 ${isModalVisible ? 'opacity-100' : 'opacity-0'}`}>
            <div className={`bg-background/95 w-[75%] h-[75%] shadow-lg transition-all duration-200 ${isModalVisible ? 'scale-100 opacity-100' : 'scale-95 opacity-0'}`}>
                <div className="relative w-full h-[30px] bg-secondary flex items-center justify-between select-none ">
                    <div className="flex items-center justify-center gap-2 pl-2">
                        <div className="font-semibold text-sm text-white">{member.name}</div>
                    </div>
                    <div className="flex items-center justify-center gap-2 hover:bg-red-500 transition-all duration-300 h-[30px] w-[30px] cursor-pointer" onClick={onClose}>
                        <X/>
                    </div>
                </div>
                <div className="w-full h-[calc(100%-30px)] p-2 overflow-y-auto">
                    <div className="flex flex-col gap-2">
                        <div className="flex flex-row items-start justify-between gap-4">
                            <div className="flex flex-col items-center gap-2">
                                <img src={`https://ui-avatars.com/api/?name=${encodeURIComponent(member.name)}&background=random&color=fff&size=128`} alt={member.name} className="w-32 h-32 rounded-full" draggable={false}/>
                                <div className="flex flex-col items-center gap-2">
                                    <h2 className="text-2xl font-bold text-primary whitespace-nowrap">{member.name}</h2>
                                    {/* <p className="text-muted-foreground whitespace-nowrap">{department.ranks.find((rank) => rank.rankId === member.rankId)?.label || "Unknown"}</p> */}
                                </div>
                            </div>
                            <div className="flex flex-col gap-2 relative w-full">
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
                                            setDepartment({
                                                ...department,
                                                members: department.members.map(m => m.identifier === member.identifier ? { ...m, rankId: parseInt(e.target.value) } : m),
                                            });
                                        }}>
                                            <option key={member.rankId} value={member.rankId}>{department.ranks.find((rank) => rank.rankId === member.rankId)?.label || "Unknown"}</option>
                                            {department.ranks.map((rank) => (rank.rankId !== member.rankId && CanRankManageRank(player.rankId, rank.rankId)) && (
                                                    <option key={rank.rankId} value={rank.rankId}>{rank.label}</option>
                                                ))}
                                            </select>
                                        ) : (
                                            <>
                                            <div className="text-sm text-muted-foreground">{department.ranks.find((rank) => rank.rankId === member.rankId)?.label || "Unknown"}</div>
                                            {player.rankId}
                                            {member.rankId}
                                            </>
                                        )}
                                    </div>
                                </div>
                                <div className="text-xl font-bold text-primary"><Translate id="permissions" /></div>
                                <div className="grid grid-cols-3 gap-2  select-none">
                                    {Object.keys(department.permissions).map((permission) => member.permissions.includes(permission) && (
                                        <div key={permission} className="relative">
                                            <div className="bg-secondary relative rounded-md p-2 font-semibold text-sm text-center">
                                                {permission}
                                                <div className="absolute inset-0 bg-red-500/95 rounded-md flex items-center justify-center opacity-0 hover:opacity-100 transition-opacity duration-200 cursor-pointer" onClick={() => {
                                                    setDepartment({
                                                        ...department,
                                                        members: department.members.map(m => m.identifier === member.identifier ? { ...m, permissions: m.permissions.filter(p => p !== permission) } : m),
                                                    });
                                                }}>
                                                    <X className="w-4 h-4 text-white" />
                                                </div>
                                            </div>
                                        </div>
                                    ))}
                                    {isAddingPermission ? (
                                        <div className="bg-secondary rounded-md p-2">
                                            <select 
                                                className="w-full bg-background text-sm p-1 rounded border border-border"
                                                value={selectedPermission}
                                                onChange={(e) => setSelectedPermission(e.target.value)}
                                            >
                                                <option value="">Select permission...</option>
                                                {Object.keys(department.permissions)
                                                    .filter(permission => !member.permissions.includes(permission))
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
                                                            setDepartment({
                                                                ...department,
                                                                members: department.members.map(m => 
                                                                    m.identifier === member.identifier 
                                                                        ? { ...m, permissions: [...m.permissions, selectedPermission] }
                                                                        : m
                                                                )
                                                            });
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
                                            className="bg-secondary rounded-md p-2 font-semibold text-sm flex items-center justify-center gap-2 cursor-pointer hover:bg-secondary/80 transition-all duration-200"
                                            onClick={() => setIsAddingPermission(true)}
                                        >
                                            <PlusIcon className="w-4 h-4" /> 
                                            <Translate id="add_permission" />
                                        </div>
                                    )}
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
                                            title: department.label.toUpperCase(),
                                            subtitle: "SHIFT REPORT",
                                            header: {
                                                title: department.label.toUpperCase(),
                                                subtitle: "SHIFT REPORT",
                                                image: "/nui/images/LSPD.webp",
                                                leftInfo: [
                                                    { label: "<span class='font-bold'>Pickle Rick</span>"},
                                                    { label: "Chief of Police"},
                                                ],
                                                rightInfo: [
                                                    { label: "<span class='font-bold'>Shift Start</span>"},
                                                    { label: "01/01/2000 12:41 PM"},
                                                    { label: "<span class='font-bold'>Shift End</span>"},
                                                    { label: "01/01/2000 12:41 PM"},
                                                ],
                                            },
                                            subContent: [
                                                { label: "<span class='font-bold'>{name}</span>" },
                                                { label: "{rank}" },
                                            ],
                                            enableContent: true,
                                            content: log.report || "",
                                            onDocumentSave: (content: any) => {
                                                console.log("SAVED", index, content);
                                                setDepartment({
                                                    ...department,
                                                    members: department.members.map(m => m.identifier === member.identifier ? { 
                                                        ...m, 
                                                        recentDutyLogs: m.recentDutyLogs.map((log, logIndex) => logIndex === index ? { 
                                                            ...log, 
                                                            report: content 
                                                        } : log) 
                                                    } : m),
                                                });
                                            }
                                        })
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

function Roster() {
    const { department } = useComputer();
    const [selectedMember, setSelectedMember] = useState<DepartmentMember | null>(department.members[department.members.length - 1]);
    const [isModalVisible, setIsModalVisible] = useState(true);

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
    return (
        <>
            {selectedMember && (
                <SelectedMemberModal memberIdentifier={selectedMember.identifier} onClose={handleMemberDeselect} isModalVisible={isModalVisible} />
            )}
            <Table maxHeight="100%" defaultSortKey="rank" data={department.members?.map((member) => ({
                ...member,
                rank: department.ranks.find((rank) => rank.rankId === member.rankId)?.label || "Unknown",
                onDutyTimeDisplay: GetStopwatchTime(member.onDutyTime),
                lastShift: member.recentDutyLogs.length > 0 ? new Date((member.recentDutyLogs[0].finish - member.recentDutyLogs[0].duration) * 1000).toLocaleString() : "Never",
                action: (<div className="flex items-center gap-2">
                    <Button variant="outline" size="icon" onClick={() => handleMemberSelect(member)} >
                        <EyeIcon className="w-4 h-4"/>
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
                        comparison = a.rankId - b.rankId;
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
        </>
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