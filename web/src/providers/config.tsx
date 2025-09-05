import React, { createContext, useContext, useState, ReactNode } from 'react';
import { useNuiEvent } from './nui/useNui';


export type Config = {
    name: string;
    identifier: string;
    disableWithdraw: boolean;
    evidenceEnabled: boolean;
    bailAndBounty: boolean;
    permissions: {
        name: string;
    }[];
    imageDirectory?: string;
    imageExtension?: string;
    locale?: Record<string, string>;
    countryCode?: string;
    currency?: string;
    items: {
        [key: string]: {
            label: string;
        };
    };
    policeArmory: {
        name: string;
    }[];
    policeGarage: {
        label: string;
        model: number;
    }[];
    garageTypes: {
        [key: string]: {
            label: string;
        };
    };
    locationTypes: {
        [key: string]: {
            locations: string[];
            settings: string[];
        };
    };
    peds: {
        label: string;
        model: string;
    }[];
    jobs: {
        [key: string]: {
            label: string;
            maxLevel: number;
        };
    };
}

interface ConfigContextProps {
    config: Config;
    setConfig: (config: Config) => void;
}

const ConfigContext = createContext<ConfigContextProps | undefined>(undefined);

export const ConfigProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
    const [config, setConfig] = useState<Config>({
        disableWithdraw: false,
        bailAndBounty: false,
        imageExtension: "png",
        locale: {
            "page_homepage": "Homepage",
            "page_roster": "Roster",
            "page_files": "Cases & Files",
            "page_settings": "Settings",
            "page_file": "File",
            "purchase": "Purchase",
            "free": "Free",
            "armory_desc": "Hover over the items to obtain them from the armory.",
            "controls_exit": "Return to Game",
            "livery": "Livery",
            "extras": "Extras",
            "extra_label": "Extra #%s",
            "color_primary": "Primary Color",
            "color_secondary": "Secondary Color",
            "take_vehicle": "Take Vehicle",
            "template": "Template",
            "no_template": "No Template",
            "add_template": "Add Template",
            "permissions": "Permissions",
            "add_permission": "Add Permission",
            "info": "Information",
            "total_on_duty": "Total Service",
            "last_shift": "Last Shift",
            "rank": "Rank",
            "recent_duty_logs": "Recent Duty Logs",
            "no_recent_duty_logs": "This member has not been on duty yet.",
            "no_permissions": "This member has no permissions.",
            "roster": "Roster",
            "ranks": "Ranks",
            "fire_member": "Fire Member",
            "confirm_fire_member": "Click again to confirm.",
            "managing_ranks": "Managers",
            "add_rank_manager": "Add Rank",
            "add_rank": "Add Rank",
            "label": "Label",
            "add_member": "Add Member",
            "delete_rank": "Delete Rank",
            "confirm_delete_rank": "Click again to confirm.",
            "delete_permission": "Delete Permission",
            "confirm_delete_permission": "Click again to confirm.",
            "police_armory": "Armory",
            "police_garage": "Garage",
            "items": "Items",
            "view_document": "View Document",
            "create_department": "Create Department",
            "return_to_departments": "Return to Departments",
            "departments": "Departments",
            "department_leader": "Department Leader",
            "none": "None",
            "locations": "Locations",
            "location_front_desk": "Front Desk",
            "location_armory": "Armory",
            "location_garage": "Garage",
            "id": "ID: %s",
            "return_to_locations": "Return to Locations",
            "create_location": "Create Location",
            "location_point": "Location",
            "location_garage_spawn": "Garage Spawn",
            "location_type": "Location Type",
            "location_create": "Create Location",
            "location_delete": "Delete Location",
            "select_player": "Select Player",
            "default_department_name": "New Department",
            "delete_department": "Delete Department",
            "delete_department_confirm": "Are you sure you want to delete this department?",
            "yes": "Yes",
            "no": "No",
            "default_rank_name": "Chief",
            "focus_off" : "Focus In-Game",
            "focus_on" : "Focus Menu",
            "setting_ped": "Ped",
            "evidence_time": "Time",
            "evidence_coords": "Coordinates",
            "evidence_direction": "Direction",
            "evidence_distance": "Distance",
            "evidence_weapon_group": "Weapon Group",
            "evidence_amount": "Amount",
            "evidence_explosion_type": "Explosion Type",
            "evidence_seat": "Seat #%s",
            "evidence_identifier": "DNA ID",
            "department_funds": "Department Funds",
            "exchange_amount": "Amount to exchange",
            "exchange_withdraw_confirm": "Withdraw",
            "exchange_deposit_confirm": "Deposit",
            "finance_withdraw": "Withdraw",
            "finance_deposit": "Deposit",
            "page_finance": "Finance",
        },
        imageDirectory: undefined,
        name: "Unknown",
        identifier: "ERR_NO_IDENTIFIER",
        currency: "GBP",
        countryCode: "en-GB",
        permissions: [],
        evidenceEnabled: true,
        items: {
            "rifle": {
                label: "Rifle"
            },
            "pistol": {
                label: "Pistol"
            },
            "smg": {
                label: "SMG"
            },
            "shotgun": {
                label: "Shotgun"
            },
            "sniper": {
                label: "Sniper"
            },
            "heavy": {
                label: "Heavy"
            },
            "handgun": {
                label: "Handgun"
            },
            "knife": {
                label: "Knife"
            },
            "flashlight": {
                label: "Flashlight"
            },
            "binoculars": {
                label: "Binoculars"
            },
            "radio": {
                label: "Radio"
            },
            "paper": {
                label: "Taser"
            },
        },
        policeArmory: [
            {
                name: "rifle",
            },
            {
                name: "pistol",
            },
            {
                name: "smg",
            },
            {
                name: "shotgun",
            },
            {
                name: "sniper",
            },
            {
                name: "heavy",
            },
            {
                name: "handgun",
            },
            {
                name: "knife",
            },
            {
                name: "flashlight",
            },
            {
                name: "binoculars",
            },
            {
                name: "radio",
            },
            {
                name: "paper",
            },
        ],
        policeGarage: [
            {
                label: "Crown Victoria",
                model: -12300341,
            },
            {
                label: "Police Interceptor",
                model: -12300342,
            },
            {
                label: "Police Interceptor Utility",
                model: -12300343,
            },
            {
                label: "Police Interceptor Utility",
                model: -12300344,
            },
        ],
        garageTypes: {
            "ERROR": {
                label: "ERROR",
            },
        },
        peds: [
            {
                label: "Male Officer #1",
                model: "s_m_m_doctor_01",
            },
            {
                label: "Female Officer #1",
                model: "s_f_y_cop_01",
            },
        ],
        locationTypes: {
            "front_desk": {
                locations: [],
                settings: ["ped"]
            },
            "armory": {
                locations: [],
                settings: ["ped"],
            },
            "garage": {
                locations: ["garage_spawn"],
                settings: ["ped"],
            },
        },
        jobs: {
        },
    });
    useNuiEvent('setConfig', (data) => {
        setConfig({ ...config, ...data.config });
    });
    return (
        <ConfigContext.Provider value={{ config, setConfig }}>
            {children}
        </ConfigContext.Provider>
    );
};

export const useConfig = (): ConfigContextProps => {
    const context = useContext(ConfigContext);
    if (!context) {
        throw new Error('useConfig must be used within a ConfigProvider');
    }
    return context;
};