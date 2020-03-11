/*
 * Copyright (c) 2020-present unTill Pro, Ltd. and Contributors
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */

package main

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/google/go-github/v29/github"
	"github.com/urfave/cli/v2"
	"golang.org/x/oauth2"
)

func main() {

	ctx := context.Background()

	var organization string
	var token string

	app := &cli.App{
		Name:  "ci-action",
		Usage: "initialize repo for ci-action",
		Flags: []cli.Flag{
			&cli.StringFlag{
				Name:        "organization",
				Value:       "untillpro",
				Usage:       "GitHub organization",
				Destination: &organization,
			},
			&cli.StringFlag{
				Name:        "token",
				Value:       "",
				Usage:       "GitHub token",
				Destination: &token,
			},
		},
		// Action: func(c *cli.Context) error {
		// 	return nil
		// },
		Commands: []*cli.Command{
			{
				Name: "list", Aliases: []string{"l"}, Usage: "show repository list",
				Action: func(c *cli.Context) error {
					fmt.Println("organization", organization)
					fmt.Println("## Repositories:")
					client := getClient(ctx, token)
					opts := &github.RepositoryListByOrgOptions{}
					for {
						repos, resp, err := client.Repositories.ListByOrg(ctx, organization, opts)
						if err != nil {
							log.Fatal(err)
						}
						for _, repo := range repos {
							if repo.Fork != nil && *repo.Fork {
								continue
							}
							fmt.Print(repo.GetName())
							if (checkForDevelopBranch(client, ctx, organization, repo.GetName())) {
								fmt.Println(" (+)")
							} else {
								fmt.Println()
							}
						}
						if resp.NextPage == 0 {
							break
						}
						opts.Page = resp.NextPage
					}
					return nil
				},
			},
			{
				Name: "init", Aliases: []string{"i"}, Usage: "initialize repository",
				Action: func(c *cli.Context) error {
					if c.Args().Len() == 0 {
						log.Fatal("specify the repository name")
					}
					repo := c.Args().First()
					client := getClient(ctx, token)

					if checkForDevelopBranch(client, ctx, organization, repo) {
						log.Print("\"develop\" branch already exist")
					} else {
						log.Print("Creating \"develop\" branch")
						masterRef, _, err := client.Git.GetRef(ctx, organization, repo, "refs/heads/master")
						if err != nil {
							log.Fatalf("Unable to get \"master\" branch: %s\n", err)
						}
						developRef := &github.Reference{Ref: github.String("refs/heads/develop"), Object: &github.GitObject{SHA: masterRef.Object.SHA}}
						_, _, err = client.Git.CreateRef(ctx, organization, repo, developRef)
						if err != nil {
							log.Fatalf("Unable to create \"develop\" branch: %s\n", err)
						}
					}

					// TODO: ...
					fmt.Println(repo)
					return nil
				},
			},
		},
	}

	err := app.Run(os.Args)
	if err != nil {
		log.Fatal(err)
	}
}

func getClient(ctx context.Context, token string) *github.Client {
	if token == "" {
		return github.NewClient(nil)
	}
	ts := oauth2.StaticTokenSource(
		&oauth2.Token{AccessToken: token},
	)
	tc := oauth2.NewClient(ctx, ts)
	return github.NewClient(tc)
}

func checkForDevelopBranch(client *github.Client, ctx context.Context, owner, repo string) bool {
	branches, _, err := client.Repositories.ListBranches(ctx, owner, repo, nil)
	if err != nil {
		log.Fatal(err)
	}
	for _, branch := range branches {
		if branch.GetName() == "develop" {
			return true
		}
	}
	return false
}
