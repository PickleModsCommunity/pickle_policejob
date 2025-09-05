import ArmoryContainer from "./components/armory/Armory"
import ComputerContainer from "./components/computer/Computer";
import DocumentContainer from "./components/document/Document"
import { GarageContainer } from "./components/garage/Garage";
import { Config, useConfig } from "./providers/config";
import { Translate } from "./providers/locale/Locale";
import ManagementDisplay from "./components/management/Management";
import Bodycam from "./components/bodycam/Bodycam";
import Camera from "./components/camera/Camera";
import FileViewer from "./components/fileviewer/FileViewer";

export function GetItemLabel({item} : {item: string}) {
  const { config } = useConfig();
  if (item == "money" || item == "dirty_money") {
    return <Translate id={item} />;
  }
  const itemLabel = config.items[item]?.label || config.items[item.toUpperCase()]?.label;
  if (!itemLabel) {
    return item;
  }
  return itemLabel;
}

export function GetItemImage(item: string) {
  const { config } = useConfig();
  return config.imageDirectory ? `${config.imageDirectory}/${item}.${config.imageExtension || "png"}` : `/nui/images/${item}.${config.imageExtension || "png"}`;
}

export function DisplayCurrency({value} : {value: number}) {
  const {config} = useConfig();
  return GetCurrencyString(value, config);
}

export function GetCurrencyString(value: number, config: Config) {
  return value.toLocaleString(config.countryCode || "en-US", {style: "currency", currency: config.currency || "USD", minimumFractionDigits: 0, maximumFractionDigits: 0});
}

export function AppControls({controls} : {controls?: {key: string, label: any}[]}) {
    const controlsList = controls || [
        {key: "ESC", label: <Translate id="controls_exit" />},
    ];
    return (
        <div className="bg-background/95 p-2 absolute top-[20px] left-[20px] flex items-center gap-2 rounded-md">
            {controlsList.map((control, index) => (
                <div className="flex items-center justify-center gap-2" key={index}>
                    <div className="relative font-bold text-sm w-[28px] h-[28px] text-black rounded-md bg-white">
                        <div className="absolute top-[50%] left-[50%] z-1" style={{transform: "translate(-50%, -50%)"}}>
                            {control.key}
                        </div>
                    </div>
                    <div className="font-bold text-xl text-primary">{control.label}</div>
                </div>
            ))}
        </div>
    )
}

function App() {
  return (
    <div className="w-screen h-screen absolute text-primary top-0 left-0">
      <ArmoryContainer />
      <ComputerContainer />
      <ManagementDisplay />
      <GarageContainer />
      <Bodycam />
      <Camera />
      <FileViewer />
    </div>
  )
}

export default App
