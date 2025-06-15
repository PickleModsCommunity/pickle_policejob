import EditorComponent from "./EditorComponent";

function DocumentHeader() {
    return (
        <div className="flex flex-col items-center gap-8 w-full pb-12">
            <h1 className="text-2xl font-bold mb-2">LOS SANTOS POLICE DEPARTMENT</h1>
            <div className="relative w-full">
                <img src="/nui/images/LSPD.webp" alt="Logo" className="absolute w-24 h-24 left-[50%] translate-x-[-50%] top-[50%] translate-y-[-50%]" />
                <div className="flex flex-row items-between justify-between w-full">
                    <div className="flex flex-col items-center">
                        <p className="text-md font-bold">Pickle Rick</p>
                        <p className="text-sm font-semibold">Chief of Police</p>
                    </div>
                    <div className="flex flex-col items-start">
                        <p className="text-sm font-semibold">{new Date().toLocaleDateString()}</p>
                        <p className="text-sm font-semibold">1 Mission Row, Los Santos, SA</p>
                    </div>
                </div>
            </div>

        </div>
    );
}
function Document() {
    const editing = true; // This can be set to true to enable editing mode
    return (
        <div className="flex flex-col w-[600px] h-[774px] p-10" style={{
            backgroundImage: 'url(/nui/images/paper.png)',
            backgroundRepeat: 'no-repeat',
            backgroundSize: 'cover',
            backgroundPosition: 'center',
            overflowY: 'auto',
        }}>
            <DocumentHeader />
            <EditorComponent config={{
                toolbar: editing,
                readonly: !editing,
            }} />
        </div>
    );
}

export default function DocumentContainer() {
    return (
        <div className="w-screen h-screen absolute text-primary top-0 left-0 bg-gray-900 flex items-center justify-center">
            <Document />
        </div>
    );
}