use leptos::*;

#[component]
pub fn Homepage(initial_value: i32) -> impl IntoView {
    // create a reactive signal with the initial value
    let (value, set_value) = create_signal(initial_value);

    // create event handlers for our buttons
    // note that `value` and `set_value` are `Copy`, so it's super easy to move them into closures
    let clear = move |_| set_value.set(0);
    let decrement = move |_| set_value.update(|value| *value -= 1);
    let increment = move |_| set_value.update(|value| *value += 1);

    // create user interfaces with the declarative `view!` macro
    view! {
        <nav class="navbar" role="navigation" aria-label="main navigation">
            <div class="navbar-menu">
                <div class="navbar-start">
                    <a class="navbar-item" >Home</a>
                    <div class="navbar-item has-dropdown is-hoverable">
                        <a class="navbar-link">
                            Projects
                        </a>
                        <div class="navbar-dropdown">
                            <a class="navbar-item">
                                Arcade
                            </a>
                        </div>
                    </div>
                    <a class="navbar-item" >About</a>
                </div>
            </div>
        </nav>
        <main>
            <div>
                <button on:click=clear>"Clear"</button>
                <button on:click=decrement>"-1"</button>
                <span>"Value: " {value} </span>
                <button on:click=increment>"+1"</button>
            </div>
        </main>
    }
}

// Easy to use with Trunk (trunkrs.dev) or with a simple wasm-bindgen setup
pub fn main() {
    mount_to_body(|| view! { <Homepage initial_value=3 /> })
}
