import React, { useRef, useState } from 'react';
import JoditEditor from 'jodit-react';
import "./styles.css"; 

interface EditorComponentProps {
    defaultContent?: string;
    onBlur?: (content: string) => void;
    onChange?: (content: string) => void;
    config: any;
}

const EditorComponent: React.FC<EditorComponentProps> = ({ config, defaultContent, onBlur, onChange }) => {
    const editor = useRef(null);
    const [content, setContent] = useState<string>(defaultContent || '');

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
                onBlur={(newContent: string) => {
                    setContent(newContent);
                    if (onBlur) {
                        onBlur(newContent);
                    }
                }}
                onChange={(newContent: string) => {
                    if (onChange) {
                        onChange(newContent);
                    }
                }}
            />
        </div>
    );
};

export default EditorComponent;