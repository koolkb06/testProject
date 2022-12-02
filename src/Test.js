import { useFetch } from './useFetch';

const baseUrl = 'https://jsonplaceholder.typicode.com';

const Test = () => {
    const { data: userData } = useFetch(baseUrl, 'users');
    const { data: postData } = useFetch(baseUrl, 'posts');

    return (
        <div>
            <h4> useFetch</h4>
            {userData && <pre>{JSON.stringify(userData[0], null, 2)}</pre>}
            {postData && <pre>{JSON.stringify(postData[0], null, 2)}</pre>}
        </div>
    );
};

export default Test;
