import React, {useEffect, useState} from 'react';

const  LifeCycle = () => {
    // const [count, setCount] = useState(0);
    // const [text, setText] = useState("");

    // useEffect(()=> {
    //     console.log("Mount!")
    // }, [])

    // useEffect(()=> {
    //     console.log("Update!")
    // })

    // useEffect(()=> {
    //     console.log(`Count Update! = ${count}`)
    //     if (count > 5) {
    //         alert("count > 5 init 1");
    //         setCount(1)
    //     }
    // },[count])

    // useEffect(()=> {
    //     console.log(`Text Update! = ${text}`)
    // },[text])

    const [isVisible, setIsVisible] = useState(false);

    const toggle = () => setIsVisible(!isVisible);


    return (
        <div style={{padding:  20}}>
            <button onClick={toggle}> ON/OFF</button> 
            {isVisible && <UnmountTest/>}
            {/* <div>
                {count}
                <betton onClick={()=>setCnunt(count+1)}> + </button>
            </div>
            <div>
                <input value={text} onChange={(e)=>setText(e.target.value)} />
            </div> */}
        </div>
    );
}
const UnmountTest = () => {

    useEffect(() => {
        console.log("Mount!");

        return ()=> {
            // Unmount 시점에 실행되게 됨

            console.log("Unmount!");

        }

    }, [])

    return <div>Unmount Testing Component </div>
}

export default LifeCycle;