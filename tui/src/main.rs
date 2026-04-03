//! Frontispiece TUI — terminal interface to the practice engine.
//!
//! Connects to the Phoenix API at localhost:4000/api.
//! Navigate with j/k, enter to select, q to quit, y to yank wells.

mod client;

use client::Client;
use crossterm::event::{self, Event, KeyCode, KeyEvent};
use crossterm::terminal::{
    disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen,
};
use crossterm::ExecutableCommand;
use ratatui::prelude::*;
use ratatui::widgets::*;
use std::io::stdout;

#[derive(Clone)]
enum Screen {
    Practices,
    Episodes(String), // practice slug
    Episode(String, String), // practice slug, episode slug
}

struct App {
    client: Client,
    screen: Screen,
    practices: Vec<client::Practice>,
    episodes: Vec<client::Episode>,
    current_episode: Option<client::EpisodeDetail>,
    selected: usize,
    well_selected: usize,
}

impl App {
    fn new(base_url: &str) -> Self {
        let client = Client::new(base_url);
        let practices = client.list_practices().unwrap_or_default();

        Self {
            client,
            screen: Screen::Practices,
            practices,
            episodes: vec![],
            current_episode: None,
            selected: 0,
            well_selected: 0,
        }
    }

    fn handle_key(&mut self, key: KeyEvent) -> bool {
        match key.code {
            KeyCode::Char('q') => return true,
            KeyCode::Char('j') | KeyCode::Down => self.move_down(),
            KeyCode::Char('k') | KeyCode::Up => self.move_up(),
            KeyCode::Enter | KeyCode::Char('l') | KeyCode::Right => self.enter(),
            KeyCode::Esc | KeyCode::Char('h') | KeyCode::Left => self.back(),
            KeyCode::Char('y') => self.yank(),
            _ => {}
        }
        false
    }

    fn move_down(&mut self) {
        let max = self.list_len().saturating_sub(1);
        if self.selected < max {
            self.selected += 1;
        }
    }

    fn move_up(&mut self) {
        if self.selected > 0 {
            self.selected -= 1;
        }
    }

    fn list_len(&self) -> usize {
        match &self.screen {
            Screen::Practices => self.practices.len(),
            Screen::Episodes(_) => self.episodes.len(),
            Screen::Episode(_, _) => {
                self.current_episode.as_ref().map(|e| e.wells.len()).unwrap_or(0)
            }
        }
    }

    fn enter(&mut self) {
        match &self.screen {
            Screen::Practices => {
                if let Some(p) = self.practices.get(self.selected) {
                    let slug = p.slug.clone();
                    self.episodes = self.client.list_episodes(&slug).unwrap_or_default();
                    self.screen = Screen::Episodes(slug);
                    self.selected = 0;
                }
            }
            Screen::Episodes(p_slug) => {
                if let Some(ep) = self.episodes.get(self.selected) {
                    let p = p_slug.clone();
                    let e = ep.slug.clone();
                    self.current_episode = self.client.get_episode(&p, &e).ok();
                    self.screen = Screen::Episode(p, e);
                    self.selected = 0;
                    self.well_selected = 0;
                }
            }
            Screen::Episode(_, _) => {
                // Toggle well selection for yanking
                self.well_selected = self.selected;
            }
        }
    }

    fn back(&mut self) {
        match &self.screen {
            Screen::Practices => {}
            Screen::Episodes(_) => {
                self.screen = Screen::Practices;
                self.selected = 0;
            }
            Screen::Episode(p, _) => {
                let slug = p.clone();
                self.screen = Screen::Episodes(slug);
                self.selected = 0;
            }
        }
    }

    fn yank(&self) {
        if let Screen::Episode(_, _) = &self.screen {
            if let Some(ep) = &self.current_episode {
                if let Some(well) = ep.wells.get(self.well_selected) {
                    // Copy to clipboard via pbcopy on macOS
                    use std::process::{Command, Stdio};
                    if let Ok(mut child) = Command::new("pbcopy")
                        .stdin(Stdio::piped())
                        .spawn()
                    {
                        use std::io::Write;
                        if let Some(mut stdin) = child.stdin.take() {
                            let _ = stdin.write_all(well.content.as_bytes());
                        }
                        let _ = child.wait();
                    }
                }
            }
        }
    }

    fn draw(&self, frame: &mut Frame) {
        let area = frame.area();

        match &self.screen {
            Screen::Practices => self.draw_practices(frame, area),
            Screen::Episodes(_) => self.draw_episodes(frame, area),
            Screen::Episode(_, _) => self.draw_episode(frame, area),
        }
    }

    fn draw_practices(&self, frame: &mut Frame, area: Rect) {
        let items: Vec<ListItem> = self
            .practices
            .iter()
            .enumerate()
            .map(|(i, p)| {
                let style = if i == self.selected {
                    Style::default().fg(Color::Black).bg(Color::White)
                } else {
                    Style::default().fg(Color::Gray)
                };
                ListItem::new(format!("  {} — {}", p.name, p.one_liner)).style(style)
            })
            .collect();

        let list = List::new(items)
            .block(Block::bordered().title(" frontispiece ").title_style(Style::default().bold()));

        frame.render_widget(list, area);
    }

    fn draw_episodes(&self, frame: &mut Frame, area: Rect) {
        let items: Vec<ListItem> = self
            .episodes
            .iter()
            .enumerate()
            .map(|(i, ep)| {
                let style = if i == self.selected {
                    Style::default().fg(Color::Black).bg(Color::White)
                } else {
                    Style::default().fg(Color::Gray)
                };
                ListItem::new(format!("  {} — {}", ep.title, ep.context)).style(style)
            })
            .collect();

        let list = List::new(items)
            .block(Block::bordered().title(" episodes ").title_style(Style::default().bold()));

        frame.render_widget(list, area);
    }

    fn draw_episode(&self, frame: &mut Frame, area: Rect) {
        if let Some(ep) = &self.current_episode {
            let chunks = Layout::vertical([
                Constraint::Length(3),
                Constraint::Min(0),
            ])
            .split(area);

            // Title bar
            let title = Paragraph::new(format!(" {} — {}", ep.title, ep.context))
                .block(Block::bordered())
                .style(Style::default().bold());
            frame.render_widget(title, chunks[0]);

            // Wells
            let items: Vec<ListItem> = ep
                .wells
                .iter()
                .enumerate()
                .map(|(i, w)| {
                    let marker = if i == self.well_selected { "▸" } else { " " };
                    let style = if i == self.selected {
                        Style::default().fg(Color::Black).bg(Color::White)
                    } else {
                        Style::default().fg(Color::Gray)
                    };
                    let preview: String = w.content.chars().take(60).collect();
                    ListItem::new(format!("{} [{}] {} — {}", marker, w.kind, w.label, preview))
                        .style(style)
                })
                .collect();

            let list = List::new(items)
                .block(Block::bordered().title(" wells (y to yank) "));
            frame.render_widget(list, chunks[1]);
        }
    }
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let base_url = std::env::var("FRONTISPIECE_URL")
        .unwrap_or_else(|_| "http://localhost:4000".to_string());

    enable_raw_mode()?;
    stdout().execute(EnterAlternateScreen)?;

    let backend = CrosstermBackend::new(stdout());
    let mut terminal = Terminal::new(backend)?;

    let mut app = App::new(&base_url);

    loop {
        terminal.draw(|f| app.draw(f))?;

        if let Event::Key(key) = event::read()? {
            if app.handle_key(key) {
                break;
            }
        }
    }

    disable_raw_mode()?;
    stdout().execute(LeaveAlternateScreen)?;
    Ok(())
}
