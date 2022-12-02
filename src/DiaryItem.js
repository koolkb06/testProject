import React, {useState, useRef, useEffect} from 'react';

const DiaryItem = ({onEdit, onRemove, author, contents, created_date, emotion, id}) => {
    useEffect(()=> {
        console.log(`${id} 번째 아이템 렌더`);

    })

    const [isEdit, setIsEdit] = useState(false)
    const toggleIsEdit = () => {
        setIsEdit(!isEdit)
    }

    const [localContents, setLocalContents] = useState(contents)

    const localContentsInput = useRef()

    const handleRemove=() => {
        if(window.confirm(`${id} 번째 일기를 정말 삭제하겠습니까?`)) {
            onRemove(id)
        }
    }

    const handleQuitEdit = () => {
        setIsEdit(false);
        setLocalContents(contents)
    }

    const handleEdit = () => {

        if (localContents.length < 5) {

            return;
        }

        if(window.confirm(`${id} 번째 일기를 수정하시겠습니까?`)) {

            onEdit(id, localContents)
            toggleIsEdit();
        }
    }


    return(
        <div className="DiaryItem">
            <div className="info">
                <span> 작성자 : {author} | 감정점수 : {emotion} </span>
                <span className="date"> {new Date(created_date).toLocaleString()} </span>
            </div>
            <div className="content">
                {isEdit ? (
                <>
                    <textarea 
                    ref={localContentsInput}
                    value={localContents} 
                    onChange={(e)=>{setLocalContents(e.target.value)}}
                    ></textarea> 
                </>) : (
                <>
                {contents}
                </>)}
                
            </div>
            { isEdit ? (
                <>
                    <button onClick={handleQuitEdit} >수정취소</button>
                    <button >수정완료</button>

                </>
            ) : (
                <>
                    <button onClick={handleRemove}>삭제하기</button>
                    <button onClick={toggleIsEdit}>수정하기</button>
                </>
            )
            }
        </div>
    )

}

export default React.memo(DiaryItem);