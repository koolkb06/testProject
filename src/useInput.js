//custom Hook
import { useState } from 'react';

export function useInput(initialValue, submitAction) {
    const [inputValue, setInputValue] = useState(initialValue);

    const handleChange = (e) => {
        setInputValue(e.target.value);
    };

    const handleSubmit = () => {
        setInputValue('');
        submitAction(inputValue);
    };

    return [inputValue, handleChange, handleSubmit]; //원하는데로 만들어줄 수 있다.
}
