import { useEffect, useState } from "react";
import { useComputer } from "./Computer";
import { Translate, translateText } from "@/providers/locale/Locale";
import { DisplayCurrency } from "@/App";
import { Button } from "../ui/button";
import { ArrowDownToLine, ArrowUpFromLine, EyeIcon, X } from "lucide-react";
import { useConfig } from "@/providers/config";
import { fetchNui } from "@/providers/nui/fetchNui";
import Table from "../table/Table";

function ExchangeModal({ isModalVisible, exchangeOpen, onClose }: { isModalVisible: boolean, exchangeOpen: "withdraw" | "deposit" | null, onClose: () => void }) {
    const { config } = useConfig();
    const [amount, setAmount] = useState<number>(1);
    return (
        <div className={`absolute inset-0 bg-background/50 backdrop-blur-sm z-[50] flex items-center justify-center transition-opacity duration-200 ${isModalVisible ? 'opacity-100' : 'opacity-0'}`}>
            <div className={`bg-background w-[90%] max-h-[90%] shadow-lg transition-all duration-200 ${isModalVisible ? 'scale-100 opacity-100' : 'scale-95 opacity-0'}`}>
                <div className="relative w-full h-[30px] bg-secondary flex items-center justify-between select-none ">
                    <div className="flex items-center justify-center gap-2 pl-2">
                        <div className="font-semibold text-sm text-white">{exchangeOpen === "withdraw" ? "Withdraw" : "Deposit"}</div>
                    </div>
                    <div className="flex items-center justify-center gap-2 hover:bg-destructive/50 transition-all duration-300 h-[30px] w-[30px] cursor-pointer" onClick={onClose}>
                        <X/>
                    </div>
                </div>
                <div className="flex flex-col gap-2 p-2">
                    <input type="number" className="w-full rounded-md border p-2 bg-background/50" value={amount} min={1} onChange={(e) => setAmount(Number(e.target.value))} placeholder={translateText(config, "exchange_amount", [])} />
                    <div className="w-full flex flex-row items-center justify-center gap-2 cursor-pointer bg-green-600 text-white font-bold text-center p-2 rounded-md hover:bg-green-700 transition-all duration-200" onClick={() => {
                        onClose();
                        fetchNui("updateComputerDepartment", {
                            type: "exchangeDepartmentFunds",
                            withdraw: exchangeOpen === "withdraw",
                            amount: amount,
                        });
                    }}>
                        {exchangeOpen === "withdraw" ? <ArrowDownToLine className="w-4 h-4" /> : <ArrowUpFromLine className="w-4 h-4" />}
                        <Translate id={"exchange_"+exchangeOpen+"_confirm"} />
                        <div className="text-white"><DisplayCurrency value={amount} /></div>
                    </div>
                </div>
            </div>
        </div>
    )
}

export default function FinancePage() {
    const {computerInfo, department} = useComputer();
    const [isModalVisible, setIsModalVisible] = useState(false);
    const [exchangeOpen, setExchangeOpen] = useState<"withdraw" | "deposit" | null>(null);
    const {config} = useConfig();
    useEffect(() => {
    }, [computerInfo]);
    return (
        <div className="relative h-full flex flex-col gap-0">
            {exchangeOpen && (
                <ExchangeModal isModalVisible={isModalVisible} exchangeOpen={exchangeOpen} onClose={() => {
                    setIsModalVisible(false);
                    setTimeout(() => {
                        setExchangeOpen(null);
                    }, 300);
                }} />
            )}
            <div className="w-full p-2">
                <div className="flex flex-col w-full rounded-md border gap-0 p-2 items-start justify-start">
                    <div className="font-bold text-xl"><Translate id="department_funds" /></div>
                    <div className="flex flex-row gap-2 items-center justify-start">
                        <div className="font-bold text-lg text-green-500">
                            <DisplayCurrency value={department.money} />
                        </div>
                        {!config.disableWithdraw && <Button variant="outline" size="sm" onClick={() => {
                            setExchangeOpen("withdraw");
                            setTimeout(() => {
                                setIsModalVisible(true);
                            }, 10);
                        }}>
                            <ArrowDownToLine className="w-4 h-4" />
                        </Button>}
                        <Button variant="outline" size="sm" onClick={() => {
                            setExchangeOpen("deposit");
                            setTimeout(() => {
                                setIsModalVisible(true);
                            }, 10);
                        }}>
                            <ArrowUpFromLine className="w-4 h-4" />
                        </Button>
                    </div>
                </div>
            </div>
            <Table defaultSortKey="date" defaultSortDirection="desc" data={department.misc.transactions.map(transaction => ({
                    ...transaction,
                    date: new Date(transaction.time * 1000).toLocaleString(),
                    amount_display: (
                        <div className={`${transaction.type === "withdraw" ? "text-red-500" : "text-green-500"}`}>
                            {transaction.type === "withdraw" ? "-" : "+"}
                            <DisplayCurrency value={transaction.amount} />
                        </div>
                    ),
                    action: (
                        <Button variant="outline" size="icon" onClick={() => {}}>
                            <EyeIcon className="w-4 h-4"/>
                        </Button>
                    ),
                }))} columns={[
                    {
                        key: "name",
                        header: "Name",
                        sortable: true,
                    },
                    {
                        key: "amount_display",
                        header: "Amount",
                        sortable: true,
                    },
                    {
                        key: "reason",
                        header: "Reason",
                        sortable: true,
                    },
                    {
                        key: "date",
                        header: "Date",
                        sortable: true,
                    },
                ]} sortFunction={(data, sortKey, sortDirection) => {
                    return data.sort((a, b) => {
                        let comparison = 0;
                        
                        if (sortKey === "date") {
                            comparison = a.time - b.time;
                        } else if (sortKey === "name") {
                            comparison = a.name.localeCompare(b.name);
                        } else if (sortKey === "amount_display") {
                            comparison = ((a.type === "withdraw" ? -1 : 1) * a.amount) - ((b.type === "withdraw" ? -1 : 1) * b.amount);
                        }
                        
                        return sortDirection === 'desc' ? -comparison : comparison;
                    });
                }} />
        </div>
    )
}