import './App.css';

import React , {useCallback, useMemo, useRef, useState, useEffect} from 'react';
import DiaryEditor from './DiaryEditor';
import DiaryList from './DiaryList';
// import OptimizeTest from './OptimizeTest';
// import LifeCycle from './LifeCycle';

function App() {

  const [data, setData] = useState([]);

  const dataId = useRef(0)

  const getData = async()=> {
    const res= await fetch(
      'https://jsonplaceholder.typicode.com/comments'
    ).then((res) => res.json()); // 원하는 json 값만 뽑아냄 

    const initData = res.slice(0,20).map((it)=> {
      return {
        author: it.email,
        contents: it.body,
        emotion: Math.floor(Math.random() * 5)+1, // *5 -> 0~4 까지 random으로 나옴, 정수로 변경 floor , +1 1~5 까지 
        created_date: new Date().getTime(),
        id:dataId.current++
      }
    });

    setData(initData);
  }

  const onCreate = useCallback((author, contents, emotion) => {
    const created_date = new Date().getTime();

    const newItem = {
      author, 
      contents, 
      emotion, 
      created_date,
      id: dataId.current
    }
    dataId.current += 1
    setData((data) => [newItem, ...data ]);
  },[]);      // 목표 : 우리는 onCreate 가 한번만 생성되길 바란다.  
              // 1. 빈배열을 넘기면 마운트 될시 한번만 불림 
              //  안되는 이유 -> onCreate 가 생성될 당시에 빈배열을 갖고 있기 때문에 현재 상태를 참고할 수 있어야 한다.  
              //                하지만 dependency array 에 빈배열을 넣으면 이전 데이터 싹 사라지고 새로운 데이터만 남음 (이상한동작을 하게됨)
              // 2. dependency array 에 data 를 넣어준다.
              //   안되는 이유 -> data 를 넣게 되면 data 가 업데이트 될때 리렌더링이 된다. 
              // 
              // 결론은 함수형 업데이트 를 사용한다. 
              // setData 이런 함수에 값을 전달해야된다고 배웠지만 함수를 전달 할 수 도 있다. 
              // data 를 전달해서 data 를 추가해서 data 를 리턴하는 함수를 전달하면 된다. => 이것이 함수형 업데이트
              // dependency array 를 비워도 정상적으로 수행됨 


  // app component 가 mount 되자마자 실행할 수 있게 
  useEffect(()=> {
    getData();
  },[])

  const onRemove= useCallback((targetId) => {
    console.log(`${targetId}가 삭제되었습니다.`)
    setData(data => data.filter((it) => it.id !== targetId)); //함수형 업데이트 
    // data 에 최신 스테이트를 전달되기 때문 
    // data 를 return 해야 최신 state 를 받게됨 
  },[]);

  const onEdit = useCallback((targetId, newContent) => {
    setData(
      (data) => (data.map((it)=>it.id === targetId ? {...it, contents:newContent}: it))
    );
  }, []);

  const getDiaryAnalysis = useMemo(() => {  // useMemo 를 사용하면 값을 return 하게 된다. 따라서 함수 실행이 아닌 74 line 끝처럼 적어줘야 한다.  

    const goodCount = data.filter((it)=> it.emotion >= 3).length;
    const badCount = data.length - goodCount;
    const goodRatio = (goodCount / data.length) * 100;

    return {goodCount, badCount, goodRatio};
  },[data.length] // useEffect 처럼 , 쓸데 없이 rerendering 하지 않도록  
  );

  const {goodCount, badCount, goodRatio} = getDiaryAnalysis; 

  return (
    <div>
      <DiaryEditor onCreate={onCreate} /> 
      <div>전체 일기 : {data.length}</div>
      <div>기분 좋은 일기 개수 : {goodCount}</div>
      <div>기분 나쁜 일기 개수 : {badCount}</div>
      <div>기분 좋은 일기 비율 : {goodRatio}</div>
      <DiaryList onEdit={onEdit} onRemove={onRemove} diaryList={data}/>
    </div>
   );
}

export default App;
 