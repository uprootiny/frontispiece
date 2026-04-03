use serde::Deserialize;

pub struct Client {
    base_url: String,
    http: reqwest::blocking::Client,
}

#[derive(Clone, Deserialize)]
pub struct Practice {
    pub name: String,
    pub slug: String,
    pub one_liner: String,
    pub episode_count: usize,
}

#[derive(Clone, Deserialize)]
pub struct Episode {
    pub title: String,
    pub slug: String,
    pub context: String,
}

#[derive(Clone, Deserialize)]
pub struct EpisodeDetail {
    pub title: String,
    pub slug: String,
    pub context: String,
    pub narration: String,
    pub wells: Vec<Well>,
}

#[derive(Clone, Deserialize)]
pub struct Well {
    pub kind: String,
    pub label: String,
    pub content: String,
    pub language: Option<String>,
}

#[derive(Deserialize)]
struct PracticeDetail {
    pub episodes: Vec<Episode>,
}

impl Client {
    pub fn new(base_url: &str) -> Self {
        Self {
            base_url: base_url.trim_end_matches('/').to_string(),
            http: reqwest::blocking::Client::builder()
                .timeout(std::time::Duration::from_secs(5))
                .build()
                .unwrap(),
        }
    }

    pub fn list_practices(&self) -> Result<Vec<Practice>, reqwest::Error> {
        self.http
            .get(format!("{}/api/practices", self.base_url))
            .send()?
            .json()
    }

    pub fn list_episodes(&self, practice_slug: &str) -> Result<Vec<Episode>, reqwest::Error> {
        let detail: PracticeDetail = self
            .http
            .get(format!("{}/api/practices/{}", self.base_url, practice_slug))
            .send()?
            .json()?;
        Ok(detail.episodes)
    }

    pub fn get_episode(
        &self,
        practice_slug: &str,
        episode_slug: &str,
    ) -> Result<EpisodeDetail, reqwest::Error> {
        self.http
            .get(format!(
                "{}/api/practices/{}/episodes/{}",
                self.base_url, practice_slug, episode_slug
            ))
            .send()?
            .json()
    }
}
