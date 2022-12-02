import React, {useEffect, useRef, useState} from 'react'

const DiaryEditor = ({onCreate}) => {

    //const [author, setAuthor] = useState("")
    //const [contents, setContents] = useState("")
    // 위에 것을 밑에 처럼 바꿀 수 있다. 

    const authorInput = useRef(); // Dom 요소를 가리킬 수 있다. 
    const contentsInput = useRef();

    const [state, setState] = useState({
        author: "",
        contents: "",
        emotion:1
    })

    const handleChangeState = (e) => {

        console.log(e.target.name)
        console.log(e.target.value)

        setState({
            ...state,
            [e.target.name]:e.target.value
        })
    }

    const handleSubmit = () => {
        if (state.author.length < 1) {
            //alert(" 작성자 최소 1글자 ")
            authorInput.current.focus();    //제대로 입력하지 않으면 focus 를 주는 
            //focus
            return;
        }

        if (state.contents.length < 5) {
            contentsInput.current.focus();
            //alert(" 일기 최소 1글자 ")
            //focus
            return;
        }

        onCreate(state.author, state.contents, state.emotion);

        alert("저장성공")

        setState({
            author:"",
            contents:"",
            emotion: 1,
        })

    }

    return (
    <div className="DiaryEditor">
        <h2> 오늘의 일기</h2>
        <div>
            <input 
                ref={authorInput}
                name='author' 
                value={state.author} 
                onChange={handleChangeState} 
            /*onChange={(e)=>{
                setState({
                    ...state,   //... spread 연산자 사용시에 위에서 아래로 업데이트 된다. 
                    author:e.target.value,
                                // 만약 ... 과 author 의 순서를 바꾸면 변경한 값이 변경한 값으로
                                // 덮어 씌워지는 현상때문에 업데이트가 안일어나는 것처럼 보임 
                })
                console.log("author =", state.author)
            }}*/ 
            ></input>
        </div>
        <div>
            <textarea 
                ref={contentsInput}
                name='contents' 
                value={state.contents} 
                onChange={handleChangeState}
            /*  // onChange 함수를 위의 handleChangeState 처럼 변경이 가능하다.  
                onChange={(e) => {
                setState({
                    ...state,
                    contents: e.target.value
                })

                console.log("contents =", state.contents)

            }}*/
            ></textarea>
        </div>
        <div>
            <select name='emotion' value={state.emotion} onChange={handleChangeState}>
                <option value={1}>1</option>
                <option value={2}>2</option>
                <option value={3}>3</option>
                <option value={4}>4</option>
                <option value={5}>5</option>
            </select>
        </div>
        <div>
            <button onClick={handleSubmit}>일기저장하기</button>
        </div>
    </div>
    )
}
export default React.memo(DiaryEditor);