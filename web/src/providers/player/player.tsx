import React, { createContext, useContext, useState, ReactNode, useEffect } from "react";
import { useNuiEvent } from "@/providers/nui/useNui";

type PlayerPermissions = string[];

type PlayerData = {
    name: string;
    departmentId: number;
    rankId: number;
    permissions: PlayerPermissions;
};

type PlayerContextProps = {
    player: PlayerData;
    hasPermission: (permission: string | string[]) => boolean;
    hasAnyPermission: (permissions: string | string[]) => boolean;
    hasAllPermissions: (permissions: string | string[]) => boolean;
};

const PlayerContext = createContext<PlayerContextProps | undefined>(undefined);

export const PlayerProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
    const [player, setPlayer] = useState<PlayerData>({
        name: "John Doe",
        departmentId: 11,
        rankId: 2,
        permissions: [],
    });

    // Handle player data updates from the game
    useNuiEvent('setPlayerData', (data: Partial<PlayerData>) => {
        setPlayer(prev => ({ ...prev, ...data }));
    });

    // Helper function to normalize permissions input
    const normalizePermissions = (permissions: string | string[]): string[] => {
        if (typeof permissions === 'string') {
            return [permissions];
        }
        if (Array.isArray(permissions)) {
            return permissions.filter(p => typeof p === 'string');
        }
        return [];
    };

    // Permission checking functions
    const hasPermission = (permission: string | string[]): boolean => {
        const normalizedPermissions = normalizePermissions(permission);
        if (normalizedPermissions.length === 0) {
            return true;
        }
        return normalizedPermissions.some(p => player.permissions.includes(p));
    };

    const hasAnyPermission = (permissions: string | string[]): boolean => {
        const normalizedPermissions = normalizePermissions(permissions);
        return normalizedPermissions.some(permission => player.permissions.includes(permission));
    };

    const hasAllPermissions = (permissions: string | string[]): boolean => {
        const normalizedPermissions = normalizePermissions(permissions);
        return normalizedPermissions.every(permission => player.permissions.includes(permission));
    };

    const value: PlayerContextProps = {
        player,
        hasPermission,
        hasAnyPermission,
        hasAllPermissions,
    };

    useEffect(() => {
        setTimeout(() => {
            setPlayer({
                ...player,
                permissions: ["Rifle Certified"],
            });
        }, 4000);
    }, []);

    return (
        <PlayerContext.Provider value={value}>
            {children}
        </PlayerContext.Provider>
    );
};

export const usePlayer = (): PlayerContextProps => {
    const context = useContext(PlayerContext);
    if (context === undefined) {
        throw new Error('usePlayer must be used within a PlayerProvider');
    }
    return context;
};
