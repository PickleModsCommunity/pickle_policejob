import React, { createContext, useContext, useState, ReactNode } from 'react';
import { useNuiEvent } from './nui/useNui';


export type Config = {
    imageDirectory?: string;
    identifier: string;
    locale?: Record<string, string>;
    countryCode?: string;
    currency?: string;
    items: {
        [key: string]: {
            label: string;
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
        locale: {
            "page_homepage": "Homepage",
            "page_roster": "Roster",
            "page_evidence": "Evidence",
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
        },
        imageDirectory: undefined,
        identifier: "ERR_NO_IDENTIFIER",
        currency: "GBP",
        countryCode: "en-GB",
        items: {},
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