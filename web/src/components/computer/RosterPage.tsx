import { useNuiEvent } from "@/providers/nui/useNui";
import { useState } from "react";
import Table from "../table/Table";
import { Translate } from "@/providers/locale/Locale";
import { Button } from "../ui/button";
import { EyeIcon, PlusIcon, X } from "lucide-react";

type DutyLog = {
    duration: number;
    finishTimestamp: string;
    startTimestamp: string;
    finish: number;
    report?: string;
}

type DepartmentMember = {
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

function SelectedMemberModal({member, onClose, isModalVisible}: {member: DepartmentMember, onClose: () => void, isModalVisible: boolean}) {
    const department = {
        label: "Los Santos Police Department",
        ranks: [{"rankId":1,"label":"Chief"},{"rankId":2,"label":"Lieutenant"},{"label":"Sergeant","rankId":3,"managingRankIds":[2]},{"label":"Officer","rankId":4,"managingRankIds":[2,3]},{"label":"Recruit","rankId":5,"managingRankIds":[2,3]}],
        permissions: {"Air Certified":{"managingRankIds":[2,3]},"Field Training Officer":{"managingRankIds":[2,3]},"Rifle Certified":{"managingRankIds":[2,3]}}
    }
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
                <div className="w-full h-[calc(100%-30px)] p-2">
                    <div className="flex flex-row items-center justify-between gap-2">
                        <div className="flex flex-col items-center gap-2">
                            <img src={`https://ui-avatars.com/api/?name=${encodeURIComponent(member.name)}&background=random&color=fff&size=128`} alt={member.name} className="w-32 h-32 rounded-full" />
                            <div className="flex flex-col items-center gap-2">
                                <h2 className="text-2xl font-bold text-primary">{member.name}</h2>
                                <p className="text-muted-foreground">{department.ranks.find((rank) => rank.rankId === member.rankId)?.label || "Unknown"}</p>
                            </div>
                        </div>
                        <div className="flex flex-col items-start gap-2">
                            <div className="text-xl font-bold text-primary"><Translate id="permissions" /></div>
                            <div className="grid grid-cols-3 gap-2  select-none">
                                {member.permissions.map((permission) => (
                                    <div className="relative">
                                        <div className="bg-secondary rounded-md p-2 font-semibold text-sm text-center">{permission}</div>
                                        <div className="absolute inset-0 bg-red-500/95 rounded-md flex items-center justify-center opacity-0 hover:opacity-100 transition-opacity duration-200 cursor-pointer">
                                            <X className="w-4 h-4 text-white" />
                                        </div>
                                    </div>
                                ))}
                                <div className="bg-secondary rounded-md p-2 font-semibold text-sm flex items-center justify-center gap-2 cursor-pointer hover:bg-secondary/80 transition-all duration-200"><PlusIcon className="w-4 h-4" /> <Translate id="add_permission" /></div>
                            </div>
                        </div>
                    </div>

                </div>
            </div>
        </div>
    )
}

export default function RosterPage() {
    const department = {
        label: "Los Santos Police Department",
        ranks: [{"rankId":1,"label":"Chief"},{"rankId":2,"label":"Lieutenant"},{"label":"Sergeant","rankId":3,"managingRankIds":[2]},{"label":"Officer","rankId":4,"managingRankIds":[2,3]},{"label":"Recruit","rankId":5,"managingRankIds":[2,3]}],
        permissions: {"Air Certified":{"managingRankIds":[2,3]},"Field Training Officer":{"managingRankIds":[2,3]},"Rifle Certified":{"managingRankIds":[2,3]}}
    }
    const [membersInfo, setMembersInfo] = useState<DepartmentMember[] | null>([
        {
            "identifier": "char1:eeee",
            "name": "Michael Rodriguez",
            "rankId": 4,
            "recentDutyLogs": [],
            "permissions": [],
            "onDutyTime": 22,
        },
        {
            "identifier": "char1:7817bde6206cb72577821aa3369e8d15f688138b",
            "name": "Sarah Johnson",
            "rankId": 2,
            "recentDutyLogs": [],
            "permissions": [],
            "onDutyTime": 256,
        },
        {
            "identifier": "char1:eeee",
            "name": "David Chen",
            "rankId": 4,
            "recentDutyLogs": [],
            "permissions": [],
            "onDutyTime": 12020,
        },
        {
            "identifier": "char1:7817bde6206cb72577821aa3369e8d15f688138b",
            "name": "Emily Thompson",
            "rankId": 2,
            "recentDutyLogs": [],
            "permissions": [],
            "onDutyTime": 42001,
        },
        {
            "identifier": "char1:eeee",
            "name": "James Wilson",
            "rankId": 4,
            "recentDutyLogs": [],
            "permissions": [],
            "onDutyTime": 2233,
        },
        {
            "identifier": "char1:7817bde6206cb72577821aa3369e8d15f688138b",
            "name": "Lisa Martinez",
            "rankId": 2,
            "recentDutyLogs": [],
            "permissions": [],
            "onDutyTime": 54321,
        },
        {
            "identifier": "char1:eeee",
            "name": "Robert Kim",
            "rankId": 4,
            "recentDutyLogs": [],
            "permissions": [],
            "onDutyTime": 2222,
        },
        {
            "identifier": "char1:7817bde6206cb72577821aa3369e8d15f688138b",
            "name": "Jennifer Davis",
            "rankId": 2,
            "recentDutyLogs": [],
            "permissions": [],
            "onDutyTime": 1123,
        },
        {
            "identifier": "char1:eeee",
            "name": "Christopher Lee",
            "rankId": 4,
            "recentDutyLogs": [],
            "permissions": [],
            "onDutyTime": 52431,
        },
        {
            "identifier": "char1:7817bde6206cb72577821aa3369e8d15f688138b",
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
                    "report": "Aoaoaoaoaoaooooooooo\n\n\nW\nW\nW\n\nW\nW\nW\nW\nW\nW\nW\nW\n\nW",
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
                "Air Certified",
                "Rifle Certified",
                "S.W.A.T.",
                "Field Training Officer",
                "Public Relations",
            ],
            "onDutyTime": 72932,
        },
    ]);
    const [selectedMember, setSelectedMember] = useState<DepartmentMember | null>(null);
    const [isModalVisible, setIsModalVisible] = useState(false);
    
    useNuiEvent("updateRosterInfo", (data: any) => {
        setMembersInfo(data.membersInfo);
    });

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
        <div className="relative w-full h-full" style={{
        }}>
            {selectedMember && (
                <SelectedMemberModal member={selectedMember} onClose={handleMemberDeselect} isModalVisible={isModalVisible} />
            )}
            <Table maxHeight="100%" defaultSortKey="rank" data={membersInfo?.map((member) => ({
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
        </div>
    )
}