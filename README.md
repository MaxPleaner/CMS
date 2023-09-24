## Background

There came a time when I wanted to create a website for my band. But I didn't want to be the only one able to edit it. My bandmates aren't developers, so they'd need to use some drag-n-drop tool.

I looked around for out-the-box solutions here. I didn't find one that I could get working on deployment, or that seemed like it did what I wanted.

Grapes.js was the closest thing - it has a great WYSIWYG editor, but unfortunately it doesn't have full CMS ability. That is to say, you have to make your own backend to handle the edited websites and host them.

So, I wrote a little Sinatra backend for that purpose.

## Will this be useful for you?

First of all, most importantly, this project is written with self-hosting in mind. It works by reading/writing HTML files _on the filesystem_. It does everything behind a single port, so it's easy to reverse proxy using Nginx. But you need to be able to read/write from the filesystem. 

Also, this doesn't currently have the ability to go super in-depth with editing HTML and CSS by hand. Possibly this functionality will be added in the future, but I'm pretty much just using the Grapes.js demo app verbatim right now, and those features aren't supported there without further customization. So, you will have to take a little time to learn the Grapes.js editor.

Another thing this doesn't have is dynamic user accounts. Users (along with passwords and site accesses) are hard-coded into a configuration file. You will have to restart the server every time it's edited. Obviously this type of system won't work for everyone. If you want dynamic accounts, you can add it to the Sinatra server, but I don't personally have that need.

What this _can_ do is create any number of sites from the web interface, create any number of subpages for each (only 1 level of nesting is allowed, though), and even use a layout file so that nav/footer/etc is shared among pages.

## Usage

This site shouldn't be such a pain to set up.

1. Clone the repo
2. Run `bundle` (currently I'm on Ruby 3.1, but it should hopefully work with other versions)
3. Create a `users.json` file (which is in .gitignore already), give it some content like this:
    ```
    [
      {
        "name": "max",
        "password": "maxs password",
        "sites": ["admin"]
      },
      {
        "name": "friend",
        "password: "friends password",
        "sites": ["site1", "site2"]
      }
    ]
    ```
   With this setup, Max has the "admin" credential, meaning he can create / edit / clone / delete sites, and also has all the site-level permissions such create / edit / clone / delete page.

   "Friend" only has access to site-level permissions on the sites listed.

4. At this point you're almost done. Just run `bundle exec ruby app.rb` for development server and `env RACK_ENV='production' bundle exec rackup` for production server.
5. Go to the site, create a page - it will prompt you to log in - it will then bring you to the site edit page, where you can create pages and view more detailed instructions about linking pages, layouts, save/publish/revert, etc.
6. Enjoy! 
