import { Config, useConfig } from "../config";
export function useLocale() {
    const { config } = useConfig();
    return (key: string, ...args: any) => {
        if (config.locale && config.locale[key]) {
            return config.locale[key].replace(/%s/g, function() {
                return args.shift();
            });
        }
        return key;
    };
}

export function translateText(config: Config, key: string, args: any[]) {
    if (config.locale && config.locale[key]) {
        return config.locale[key].replace(/%s/g, function() {
            return args.shift();
        });
    }
    return key;
}

export function Translate({id, args = [], callback} : {id: string, args?: any[], callback?: (rawText: string) => string}) {
    const locale = useLocale();
    return callback ? callback(locale(id, ...(args || []))) : locale(id, ...(args || []));
}