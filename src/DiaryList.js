import DiaryItem from "./DiaryItem";

const DiaryList = ({onEdit, onRemove, diaryList}) => {
    console.log("diaryList", diaryList)

    return(
        <div className="DiaryList">
            <h2>일기 리스트</h2>
            <h4> {diaryList.length} 개의 일기가 있습니다.</h4>
            <div>
                {diaryList.map((it) => (
                    <DiaryItem key={it.id} {...it} onEdit={onEdit} onRemove={onRemove} />
                ))}
            </div>
        </div>
    );
};

DiaryList.defaultProps={
    diaryList: []           //undefined이 props 로 내려왔을 때 에러를 방지해줌
}

export default DiaryList;