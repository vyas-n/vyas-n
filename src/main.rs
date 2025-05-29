use leptos::*;
use leptos_router::*;

#[component]
fn Homepage(initial_value: i32) -> impl IntoView {
    // create a reactive signal with the initial value
    let (value, set_value) = create_signal(initial_value);

    // create event handlers for our buttons
    // note that `value` and `set_value` are `Copy`, so it's super easy to move them into closures
    let clear = move |_| set_value.set(0);
    let decrement = move |_| set_value.update(|value| *value -= 1);
    let increment = move |_| set_value.update(|value| *value += 1);

    // create user interfaces with the declarative `view!` macro
    view! {
        <div class="container">
            <h1 class="title">
                Homepage
            </h1>

            <p>
                "Hello! Welcome to my website!"<br/>
                "There's not much to see here, I just use this website to try some rust programming."<br/>
                "Feel free to visit my About page for more info about me."
            </p>

            <div class="column">
                <span>"Current Value: " {value} </span>
                <div>
                    <button class="button" on:click=clear>"Clear"</button>
                    <button class="button" on:click=decrement>"-1"</button>
                    <button class="button" on:click=increment>"+1"</button>
                </div>
            </div>
        </div>
    }
}

#[component]
fn Projects() -> impl IntoView {
    view! {
        <p>"This is the Projects Page."</p>
    }
}

#[component]
fn About() -> impl IntoView {
    view! {
        <div class="container">
            <h1 class="title">
                "About Me"
            </h1>
            <br/>
            <p class="subtitle">
                "Hi! My name is Vyas and this is my website!"<br/>
            </p>
            <p>
                "I know it's not much to look at, this is just a testing ground for me to practice learning new things."<br/><br/>
                "If you're a recruiter looking at this page, please don't. 😅"<br/>
                "Take a look at my online profiles instead:"
            </p>
            <ol style="margin-left: 40px" type="I" class="list">
                <li class="list-item">
                    <span >"LinkedIn: "<a href="https://www.linkedin.com/in/vyas-n/">"linkedin.com/in/vyas-n"</a></span>
                </li>
                <li class="list-item">
                    <span >"GitHub: "<a href="https://github.com/vyas-n">"github.com/vyas-n"</a></span>
                </li>
            </ol>
        </div>
    }
}

#[component]
fn App() -> impl IntoView {
    view! {
        <Router>
            <nav class="navbar" role="navigation" aria-label="main navigation">
                <div class="navbar-menu">
                    <div class="navbar-start">
                        <a class="navbar-item" href="/">Home</a>
                        // TODO: add projects navbar-item
                        // <div class="navbar-item has-dropdown is-hoverable">
                        //     <a class="navbar-link" href="/projects">
                        //         Projects
                        //     </a>
                        //     <div class="navbar-dropdown">
                        //         <a class="navbar-item">
                        //             Arcade
                        //         </a>
                        //     </div>
                        // </div>
                        <a class="navbar-item" href="/about">About</a>
                    </div>
                </div>
            </nav>
            <main>
                <Routes>
                    <Route path="/" view=|| view! { <Homepage initial_value=3 /> } />
                    <Route path="/about" view=|| view! { <About /> } />
                    // TODO: add projects page
                    // <Route path="/projects" view=|| view! { <Projects /> } />
                    <Route path="/*any" view=|| view! { <h1>"Not Found"</h1> }/>
                </Routes>
            </main>
        </Router>
    }
}

// Easy to use with Trunk (trunkrs.dev) or with a simple wasm-bindgen setup
fn main() {
    mount_to_body(App)
}
