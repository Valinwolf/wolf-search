### how to use this with a docker instance
1. Clone repo to local machine note path. (in the example repo is cloned to /root/proj)  
2. Within the `searxng:` service block in your docker compose file you should add these two lines (updated to align with your local machine cloned repo path) to the `volumes:` section.  
    ```
    services:
      searxng:
        volumes:
          - '/root/proj/simply-nord/out/crabx:/usr/local/searxng/searx/templates/simple'
          - '/root/proj/simply-nord/out/crabx-static:/usr/local/searxng/searx/static/themes/simple'
    ```  
    **Shorthand mount syntax is `- '[source path on local machine]:[target path in container]'`. This overwrites/replaces the in-container target folder.**   
  3. Double check the source path on local machine is correct for where you cloned the project.  
  4. In client side user settings 'simple' will still be selected but the theme is now the modified one, and the light/dark/black selector near it will adjust the color scheme for this modded theme as expected.  

---

### key goals of this project
- [x] Workflow to granularly extend SearXNG's default "Simple" theme, and build into the deploy-ready merged theme assets
- [x] Nord colors swaps for everything
- [x] Minimalist for increased readability and aesthetics
- [x] Fixes for deal-breaker mobile layout issues (like mobile views with unnecessary horional scrolling that is plaguing the web)

**Completeness disclaimer**: as a perfectionist, it is not at 100% polished yet (is anything these days!?), but I use it daily on my personal instance, and enjoy using it.

**Style Inspiration**: mostly inspired by google's design and my preferences

**May break things disclaimer**: This theme is not recommended for public use, removes all info/branding and could obstruct native features. It is intended for users that are okay with the opinionated tradeoffs made.
