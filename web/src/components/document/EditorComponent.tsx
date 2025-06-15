import React, { useRef, useState } from 'react';
import JoditEditor from 'jodit-react';
import "./styles.css"; 

interface EditorComponentProps {
    config: any;
}

const EditorComponent: React.FC<EditorComponentProps> = ({ config }) => {
    const editor = useRef(null);
    const [content, setContent] = useState<string>('');

    return (
        <div className='w-full h-full'>
            <JoditEditor
                ref={editor}
                value={content}
                config={{
                    statusbar: false,
                    toolbar: true,
                    readonly: false,
                    toolbarButtonSize: 'middle',
                    buttons: ['bold', 'italic', 'underline', 'link', 'unlink', 'source'],
                    uploader: {
                        insertImageAsBase64URI: true,
                    },
                    ...config,
                }}
                tabIndex={1} // tabIndex of textarea
                onBlur={(newContent: string) => setContent(newContent)}
                onChange={(newContent: string) => {}}
            />
        </div>
    );
};

export default EditorComponent;