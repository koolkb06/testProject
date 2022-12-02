
import React, {useState, useEffect} from 'react';

const CounterA = React.memo(({count})=> {

    useEffect(()=>{
        console.log(`CounterA update- count = ${count}`)
    })

    return <div>{count}</div>
});

const CounterB = ({obj})=> {
    useEffect(()=>{
        console.log(`CounterB update- obj= ${obj.count}`)
    })

        return <div>{obj.count}</div>
};

const areEqual = (prevProps, nextProps) => {
    if (prevProps.obj.count === nextProps.obj.count) {
        return true;
    } 
    return false;
}

const MemoizedCounterB = React.memo(CounterB, areEqual);


// const Textview= React.memo(({text})=>{
//     useEffect(() => {
//         console.log(`Update :: Text ${text}` )
//     });
//     return <div>{text}</div>

// });


// const Countview= React.memo(({count})=>{
//     useEffect(() => {
//         console.log(`Update :: Count ${count}` )
//     });
//     return <div>{count}</div>

// });

const OptimizeTest = () => {

    const [count, setCount] = useState(1);
    const [obj, setObj] = useState({
        count:1
    })

//    const [text, setText] = useState("");

    return <div style={{padding:50}}> 
        <div>
        <h2>Counter A </h2>
            <CounterA count={count}></CounterA>
            <button onClick={()=> setCount(count)}> A button</button>
        </div>
        <div>
            <h2>Counter B</h2>
            <MemoizedCounterB obj={obj}></MemoizedCounterB>
            <button onClick={()=> setObj({
                count:obj.count,
            })}> B button</button>
    

        </div>
    </div>
};

export default OptimizeTest;
